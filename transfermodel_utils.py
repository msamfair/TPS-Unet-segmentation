# MDSF 07/13/2020
# Here are several functions to prepare image and TPS files for model training
# and then output model predictions back into a TPS file

"""Loads several functions that prepare images and TPS files for model training and then write predictions to a TPS file

Troubleshooting:
    - If you are not entering absolute path names, change the working directory to a folder
    containing all the necessary python and R scripts
    - This script was written in Python 3.7 using Tensorflow 1.15.0; Tensorflow 2 will cause errors
    - Dependencies include: os, glob, PIL, tensorflow, numpy, py_tps, matplotlib, scipy, cv2, and subprocess
    - This script assumes images are named in the format "BUN_SHUB-1-01.tif" and TPS files are named in the format
    "BUN_SHUB-1-digitized.tps"
"""

#Makes a folder with image and mask subfolders for every training image
def MakeFolders (PathtoImages, WorkingDirectory):
    """MakeFolders makes a folder in the working directory with image and mask subfolders for every training image

    Args:
        PathtoImages should be the full path name to where the TIFF images for model training are stored
        WorkingDirectory is the folder containing all the necessary python and R scripts
    """
    import os
    import glob
    os.chdir(PathtoImages)

    if not os.path.exists((WorkingDirectory + "/Training")):
        os.mkdir((WorkingDirectory + "/Training"))
    for file in glob.glob('*.tif'):
        SpecimenName = file.split('.')[0]
        os.mkdir(WorkingDirectory + "/Training/" + SpecimenName + "/")
        os.mkdir(WorkingDirectory + "/Training/" + SpecimenName + '/images/')
        os.mkdir(WorkingDirectory + "/Training/" + SpecimenName + '/masks/')

#Convert tif images to png
def TIFtoPNG (PathtoImages, WorkingDirectory, Crop=False):
    """ Use after MakeFolders()
        Converts TIFF images in PathtoImages to PNG images in the working directory

    Args:
        PathtoImages should be the full path name to where the TIFF images for model training are stored
        WorkingDirectory is the folder containing all the necessary python and R scripts
        Crop: The images will be resized to be square either by padding or cropping. The default is
        padding, so Crop=False by default

    Notes:
        So long as MakeFolders() has already been used, the resized PNG images will be saved to their namesake
        folders in the working directory
    """
    from PIL import Image
    import os
    import glob
    import tensorflow as tf
    import numpy as np
    os.chdir(PathtoImages)

    for file in glob.glob('*.tif'):
        image = Image.open(file)
        image_size = image.size
        width = image_size[0]
        height = image_size[1]
        #rgb_im = im.convert('RGB')
        if (width != height):
            if (Crop==False):
                bigside = width if width > height else height
                resized_im = tf.image.resize_with_crop_or_pad(image, bigside, bigside)
                with tf.Session() as sess:
                    image_out = sess.run(fetches=resized_im)
                    assert isinstance(image_out, np.ndarray)
                image_out = Image.fromarray(image_out)
                image_out.save(WorkingDirectory + "/Training/" + file.split('.')[0] + '/images/' + file.replace("tif", "png"))
            if (Crop==True):
                shortside = width if width < height else height
                resized_im = tf.image.resize_with_crop_or_pad(image, shortside, shortside)
                with tf.Session() as sess:
                    image_out = sess.run(fetches=resized_im)
                    assert isinstance(image_out, np.ndarray)
                image_out = Image.fromarray(image_out)
                image_out.save(WorkingDirectory + "/Training/" + file.split('.')[0] + '/images/' + file.replace("tif", "png"))
        else:
            image.save(WorkingDirectory + "/Training/" + file.split('.')[0] + '/images/' + file.replace("tif", "png"))

# Create masks for every training image based on a tps file
def MakeMasks (PathtoImages, WorkingDirectory, *TPS_files, Crop=False):
    """Use after MakeFolders(), creates a training mask for every image and puts it in its namesake folder in the
    working directory

    Args:
        *TPS_files can take any number of full TPS_file path names separated by commas
        PathtoImages should be the full path name to where the TIFF images for model training are stored
        WorkingDirectory is the folder containing all the necessary python and R scripts, as well as
        the folders created by MakeFolders()
        Crop: The masks will be resized to be square either by padding or cropping. The default is
        padding, so Crop=False by default

    Notes:
        If the TPS files' IDs are in the form BUN_SHUB-1-01, this function will replace them with integers (01, 02, etc)
    """

    import py_tps
    from py_tps import TPSFile, TPSImage, TPSCurve, TPSPoints
    import numpy as np
    import matplotlib
    import matplotlib.pyplot as plt
    import scipy
    import cv2 as cv
    import PIL
    import os
    import glob
    from PIL import Image
    import subprocess
    import tensorflow as tf
    WorkingDirectoryPath = WorkingDirectory + "/Training"

    # Changing the TPS IDs to integers in order to read the file
    for TPS_file in TPS_files:
        Filename = TPS_file.split("/",-1)[5]
        PopName = Filename.split("-",-1)[0] + "-" + Filename.split("-",-1)[1] + "-"
        with open(TPS_file, "r") as TPSedit_in:
            new_file = ""
            for line in TPSedit_in:
                if line.startswith('ID'):
                    newline = line.replace(PopName, "")
                    new_file += newline
                else:
                    newline = line
                    new_file += newline
            TPSedit_in.close()
            TPSedit_out = open(TPS_file, "w")
            TPSedit_out.write(new_file)
            TPSedit_out.close()

    # Create mask images from tps file and save the tps files to their namesake folder in WorkingDirectory
    for TPS_file in TPS_files:
        tps_file_in = TPSFile.read_file(TPS_file)
        ListLength = len(tps_file_in.images)

        for i in range(0,ListLength):
            img = tps_file_in.images[i].image.split(".", maxsplit=1)
            img = img[0]
            if tps_file_in.images[i].curves is None:
                print("No curve for image {ImageName}".format(ImageName=img))
            else:
                try:
                    subprocess.call(['Rscript', '--vanilla', '/Users/mayasamuels-fair/Desktop/WorkingFolder/mask_from_tps.R', PathtoImages, WorkingDirectory, img],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    # Resize masks
                    path = "{Folder}{ImageName}.png".format(Folder=WorkingDirectoryPath + '/' + img + '/masks/', ImageName=img)
                    image = Image.open(path)
                    image_size = image.size
                    width = image_size[0]
                    height = image_size[1]
                    image = image.convert('RGB')
                    if (width != height):
                        if (Crop==False):
                            bigside = width if width > height else height
                            resized_im = tf.image.resize_with_crop_or_pad(image, bigside, bigside)
                            with tf.Session() as sess:
                                image_out = sess.run(fetches=resized_im)
                                assert isinstance(image_out, np.ndarray)
                            image_out = Image.fromarray(image_out)
                            image_out.save(WorkingDirectory + "/Training/" + img + '/masks/' + img + '.png')
                        if (Crop==True):
                            shortside = width if width < height else height
                            resized_im = tf.image.resize_with_crop_or_pad(image, shortside, shortside)
                            with tf.Session() as sess:
                                image_out = sess.run(fetches=resized_im)
                                assert isinstance(image_out, np.ndarray)
                            image_out = Image.fromarray(image_out)
                            image_out.save(WorkingDirectory + "/Training/" + img + '/masks/' + img + '.png')
                except:
                    print("Skipping {ImageName}".format(ImageName=img))

# Resize the TIFF images on which you want to use your trained
def ResizeTestImages (PathtoTestImages, WorkingDirectory, ImageSize, Crop=False):
    """This function pads or crops images to the size on which the model was trained

    Args:
        PathtoTestImages is the full path name to the folder containing the images on which the model will be tested
        WorkingDirectory is the folder containing all the necessary python and R scripts, as well as
        the folders created by MakeFolders()
        ImageSize should be one integer: the width or height to which the test images should be resized
        (they must be square, so the width and height should be equivalent)
        Crop: The test images will be resized to be square either by padding or cropping. The default is
        padding, so Crop=False by default
    """

    from PIL import Image
    import os
    import glob
    os.chdir(PathtoTestImages)

    for file in glob.glob('*.tif'):
        image = Image.open(file)
        image_size = image.size
        width = image_size[0]
        height = image_size[1]
        if (width != height):
            if (Crop==False):
                bigside = width if width > height else height
                resized_im = tf.image.resize_with_crop_or_pad(image, bigside, bigside)
                with tf.Session() as sess:
                    image_out = sess.run(fetches=resized_im)
                    assert isinstance(image_out, np.ndarray)
                image_out = Image.fromarray(image_out)
            if (Crop==True):
                shortside = width if width < height else height
                resized_im = tf.image.resize_with_crop_or_pad(image, shortside, shortside)
                with tf.Session() as sess:
                    image_out = sess.run(fetches=resized_im)
                    assert isinstance(image_out, np.ndarray)
                image_out = Image.fromarray(image_out)
        resized_im = image_out.resize((ImageSize, ImageSize))
        if not os.path.exists((WorkingDirectory + "/Test")):
            os.mkdir((WorkingDirectory + "/Test"))
        resized_im.save(WorkingDirectory + "/Test/" + file.replace("tif", "png"))

def PrepareData (PathtoImages, WorkingDirectory, PathtoTestImages, ImageSize, *TPS_files, Crop=False):
    """This function runs MakeFolders(), TIFtoPNG(), MakeMasks(), and ResizeTestImages()

    Args:
        PathtoImages should be the full path name to where the TIFF images for model training are stored
        WorkingDirectory is the folder containing all the necessary python and R scripts, as well as
        the folders created by MakeFolders()
        PathtoTestImages is the full path name to the folder containing the images on which the model will be tested
        ImageSize should be one integer: the width or height to which the test images should be resized
        (they must be square, so the width and height should be equivalent)
        *TPS_files can take any number of full TPS_file path names separated by commas
        Crop: The test images will be resized to be square either by padding or cropping. The default is
        padding, so Crop=False by default

    Notes:
        If there is an error, each component function can also be called individually
    """

    from tqdm import tqdm

    tqdm(MakeFolders(PathtoImages, WorkingDirectory))
    print("MakeFolders() is done")
    tqdm(TIFtoPNG(PathtoImages, WorkingDirectory, Crop))
    print("TIFtoPNG() is done")
    tqdm(MakeMasks(PathtoImages, WorkingDirectory, *TPS_files, Crop))
    print("MakeMasks() is done")
    tqdm(ResizeTestImages(PathtoTestImages, WorkingDirectory, ImageSize))
    print("ResizeTestImages() is done")
    print("Data is ready for model training")

def WriteMultipletoTPS (FolderofContourFiles, WorkingDirectory, PopName, Scale):
    """After the model has written contour files for each specimen in a population,
    use this to combine those contour files into one

    Args:
        FolderofContourFiles is the full path to the files output by make_predictions.py
        PopName should be in the format BUN_SHUB-1
        Scale is the scale that should be written in the TPS file
    """
    import numpy as np
    import matplotlib.pyplot as plt
    import py_tps
    from py_tps import TPSFile, TPSImage, TPSCurve, TPSPoints
    import cv2
    import glob
    os.chdir(FolderofContourFiles)

    for ContourFile in glob.glob("*.txt"):
        SpecimenName = ContourFile.split("_")[2] + "_" + ContourFile.split("_")[3] + ".tif"
        SpecimenID = ContourFile.split("-")[2]

        #Write TPS file
        with open(ContourFile) as f:
            newfile = ""
            for line in f:
                newline = line.replace("[","")
                newline = newline.replace("]","")
                newfile += newline
            f.close()
            fnew = open(ContourFile, "w")
            fnew.write(newfile)
            fnew.close()

        with open(ContourFile) as f:
            lines = f.readlines()
            x = []
            y = []
            for line in lines:
                try:
                    x += [float(line.split()[0])]
                    y += [float(line.split()[1])]
                except:
                    ExceptMessage = "It's just blank lines causing an error"
        coords = np.empty((len(x),2))
        for i in range(len(x)):
            coords[i] = [x[i], y[i]]
        points = TPSPoints(coords)
        curve = TPSCurve(points)
        image = TPSImage(SpecimenName, curves=[curve], id_number=SpecimenID, scale=Scale)
        tps_file = TPSFile([image])
        if not os.path.exists((WorkingDirectory + "/TPS")):
            os.mkdir((WorkingDirectory + "/TPS"))
        tps_file.write_to_file((WorkingDirectory + '/TPS/{Name}.TPS'.format(Name=SpecimenName)))

    #Append these text files
    os.chdir((WorkingDirectory + '/TPS'))
    read_files = glob.glob("*.TPS")
    with open("{Name}.TPS".format(Name = PopName), "wb") as outfile:
        for f in read_files:
            with open(f, "rb") as infile:
                outfile.write(infile.read())
                os.remove(f)