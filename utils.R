# MDSF 07/20/20
# Functions to replace transfermodel_utils.py in R

library(tiff)
library(jpeg)
library(raster)

MakeFolders <- function(PathtoImages, WorkingDirectory, TIF=TRUE) {
  if (file.exists(paste(WorkingDirectory, "/Training", sep=""))) {
    setwd(PathtoImages)
  } else {
    dir.create((paste(WorkingDirectory, "/Training", sep="")))
    setwd(PathtoImages)
  }
  if (TIF==TRUE) {
    for (file in Sys.glob('*.tif')) {
      SpecimenName <- strsplit(file, "[.]")[[1]][1]
      dir.create((paste(WorkingDirectory, "/Training/", SpecimenName, sep="")))
      dir.create((paste(WorkingDirectory, "/Training/", SpecimenName, "/images/", sep="")))
      dir.create((paste(WorkingDirectory, "/Training/", SpecimenName, "/masks/", sep="")))
      }
      } else {
        for (file in Sys.glob('*.jpg')) {
          SpecimenName <- strsplit(file, "[.]")[[1]][1]
          dir.create((paste(WorkingDirectory, "/Training/", SpecimenName, sep="")))
          dir.create((paste(WorkingDirectory, "/Training/", SpecimenName, "/images/", sep="")))
          dir.create((paste(WorkingDirectory, "/Training/", SpecimenName, "/masks/", sep="")))
      }
    }
  }

ToPNG <- function(PathtoImages, WorkingDirectory, TIF=TRUE) {
  setwd(PathtoImages)
  if (TIF==TRUE) {
    for (file in Sys.glob('*.tif')) {
      SpecimenName <- strsplit(file, "[.]")[[1]][1]
      ImagePath <- paste(PathtoImages, "/", file, sep="")
      imagefordims <- readTIFF(ImagePath)
      img <- image_read(ImagePath)
      pixh <- dim(imagefordims)[1]
      pixw <- dim(imagefordims)[2]
      if (pixw > pixh) {
        bigside <- pixw
      } else {
        bigside <- pixh
      }
      SavePath <- paste(WorkingDirectory, "/Training/", SpecimenName, "/images/", SpecimenName, sep="")
      addx <- (bigside - pixw)/2
      addy <- (bigside - pixh)/2
      pad <- paste(as.character(addx), "X", as.character(addy), sep="")
      img <- image_border(img, "black", pad)
      image_write(img, path=MaskPath, format="png")
    }
  }
  if (TIF==FALSE) {
    for (file in Sys.glob('*.jpg')) {
      SpecimenName <- strsplit(file, "[.]")[[1]][1]
      ImagePath <- paste(PathtoImages, "/", file, sep="")
      imagefordims <- readJPEG(ImagePath)
      img <- image_read(ImagePath)
      pixh <- dim(imagefordims)[1]
      pixw <- dim(imagefordims)[2]
      if (pixw > pixh) {
        bigside <- pixw
      } else {
        bigside <- pixh
      }
      SavePath <- paste(WorkingDirectory, "/Training/", SpecimenName, "/images/", SpecimenName, sep="")
      addx <- (bigside - pixw)/2
      addy <- (bigside - pixh)/2
      pad <- paste(as.character(addx), "X", as.character(addy), sep="")
      img <- image_border(img, "black", pad)
      image_write(img, path=MaskPath, format="png")
    }
  }
}

MakeMasks <- function(PathtoImages, WorkingDirectory, TIF=TRUE) {
  library(raster)
  library(magick)
  tps_utils_path <- paste(WorkingDirectory, '/tps-oo.R', sep="")
  source(tps_utils_path)
  setwd(PathtoImages)
  # Get image file for specimen
  if (TIF==TRUE) {
    for (file in Sys.glob('*.tif')) {
      ImageName <- strsplit(file, "[.]")[[1]][1]
      ImagePath <- paste(PathtoImages, '/', ImageName, ".tif", sep="")
      image <- readTIFF(ImagePath)
      pixh <- dim(image)[1]
      pixw <- dim(image)[2]
      
      # Read in TPS file, extract xy coords of curve from specimen
      species <- strsplit(ImageName,"-")[[1]][1]
      pop <- strsplit(ImageName,"-")[[1]][2]
      individual <- as.integer(strsplit(ImageName,"-")[[1]][3])
      PopName <- paste(species, "-", pop, sep="")
      TPSpath <- paste(PathtoImages, '/', PopName, "-digitized.tps", sep="")
      cc <- read.tps(TPSpath)
      c1 <- cc[[individual]]$curve1.points
      c1c <- rbind(c1, c1[1,])  # add start point to the end to close the polygon
      
      # the important part - make a PNG file and plot curve to it
      MaskPath <- paste(WorkingDirectory, '/Training/', ImageName, "/masks/", ImageName, ".png", sep="")
      if (pixw > pixh) {
        bigside <- pixw
      } else {
        bigside <- pixh
      }
      png(filename = MaskPath, width = pixw, height = pixh, bg = "black")
      par(mai = c(0,0,0,0), xaxs = "i", yaxs = "i")
      plot(c1c, typ="n", xlim=c(0, pixw), ylim=c(0, pixh))
      polygon(c1c, col = "white")
      dev.off()
      img <- image_read(MaskPath)
      addx <- (bigside - pixw)/2
      addy <- (bigside - pixh)/2
      pad <- paste(as.character(addx), "X", as.character(addy), sep="")
      img <- image_border(img, "black", pad)
      image_write(img, path=MaskPath, format="png")
    }
  } else {
    for (file in Sys.glob('*.jpg')) {
      ImageName <- strsplit(file, "[.]")[[1]][1]
      ImagePath <- paste(PathtoImages, '/', ImageName, ".jpg", sep="")
      image <- readJPEG(ImagePath)
      pixh <- dim(image)[1]
      pixw <- dim(image)[2]
      
      # Read in TPS file, extract xy coords of curve from specimen
      species <- strsplit(ImageName,"-")[[1]][1]
      pop <- strsplit(ImageName,"-")[[1]][2]
      individual <- as.integer(strsplit(ImageName,"-")[[1]][3])
      PopName <- paste(species, "-", pop, sep="")
      TPSpath <- paste(PathtoImages, '/', PopName, "-digitized.tps", sep="")
      cc <- read.tps(TPSpath)
      c1 <- cc[[individual]]$curve1.points
      c1c <- rbind(c1, c1[1,])  # add start point to the end to close the polygon
      
      # the important part - make a PNG file and plot curve to it
      MaskPath <- paste(WorkingDirectory, '/Training/', ImageName, "/masks/", ImageName, ".png", sep="")
      if (pixw > pixh) {
        bigside <- pixw
      } else {
        bigside <- pixh
      }
      png(filename = MaskPath, width = pixw, height = pixh, bg = "black")
      par(mai = c(0,0,0,0), xaxs = "i", yaxs = "i")
      plot(c1c, typ="n", xlim=c(0, pixw), ylim=c(0, pixh))
      polygon(c1c, col = "white")
      dev.off()
      img <- image_read(MaskPath)
      addx <- (bigside - pixw)/2
      addy <- (bigside - pixh)/2
      pad <- paste(as.character(addx), "X", as.character(addy), sep="")
      img <- image_border(img, "black", pad)
      image_write(img, path=MaskPath, format="png")
    }
  }
}
  
ResizeTestImages <- function(PathtoTestImages, WorkingDirectory, ImageSize, TIF=TRUE) {
  setwd(PathtoTestImages)
  require(magick)
  if (TIF==TRUE) {
    for (file in Sys.glob('*.tif')) {
      SpecimenName <- strsplit(file, "[.]")[[1]][1]
      ImagePath <- paste(PathtoTestImages, "/", file, sep="")
      imagefordims <- readTIFF(ImagePath)
      img <- image_read(ImagePath)
      pixh <- dim(imagefordims)[1]
      pixw <- dim(imagefordims)[2]
      if (pixw > pixh) {
        bigside <- pixw
      } else {
        bigside <- pixh
      }
      addx <- (bigside - pixw)/2
      addy <- (bigside - pixh)/2
      pad <- paste(as.character(addx), "X", as.character(addy), sep="")
      img <- image_border(img, "black", pad)
      dims <- paste(ImageSize, "X", ImageSize, sep="")
      img <- image_resize(img, dims)
      SavePath <- paste(WorkingDirectory, "/Test/", SpecimenName, sep="")
      if (file.exists(paste(WorkingDirectory, "/Test", sep=""))) {
        image_write(img, path=SavePath, format="png")
      } else {
        dir.create((paste(WorkingDirectory, "/Test", sep="")))
        image_write(img, path=SavePath, format="png")
      }
      }
    }
  if (TIF==FALSE) {
    for (file in Sys.glob('*.jpg')) {
      SpecimenName <- strsplit(file, "[.]")[[1]][1]
      ImagePath <- paste(PathtoTestImages, "/", file, sep="")
      img <- image_read(ImagePath)
      imagefordims <- readJPEG(ImagePath)
      pixh <- dim(imagefordims)[1]
      pixw <- dim(imagefordims)[2]
      if (pixw > pixh) {
        bigside <- pixw
      } else {
        bigside <- pixh
      }
      addx <- (bigside - pixw)/2
      addy <- (bigside - pixh)/2
      pad <- paste(as.character(addx), "X", as.character(addy), sep="")
      img <- image_border(img, "black", pad)
      dims <- paste(ImageSize, "X", ImageSize, sep="")
      img <- image_resize(img, dims)
      SavePath <- paste(WorkingDirectory, "/Test/", SpecimenName, sep="")
      if (file.exists(paste(WorkingDirectory, "/Test", sep=""))) {
      image_write(img, path=SavePath, format="png")
      } else {
        dir.create((paste(WorkingDirectory, "/Test", sep="")))
        image_write(img, path=SavePath, format="png")
      }
    }
  }
}

PrepareData <- function(PathtoImages, WorkingDirectory, PathtoTestImages, ImageSize, TIF=TRUE) {
  MakeFolders(PathtoImages, WorkingDirectory, TIF)
  TIFtoPNG(PathtoImages, WorkingDirectory, TIF)
  MakeMasks(PathtoImages, WorkingDirectory, TIF)
  ResizeTestImages(PathtoTestImages, WorkingDirectory, ImageSize, TIF)
}

WriteMultipletoTPS <- function(FolderofContourFiles, WorkingDirectory, PopName, Scale, TIF=TRUE) {
  setwd(FolderofContourFiles)
  PopFile <- paste(PopName, ".tps", sep="")
  library(readr)
  for (ContourFile in Sys.glob('*.txt')) {
    if (TIF==TRUE) {
    SpecimenName <- paste(strsplit(ContourFile, "_")[[1]][3], "_", strsplit(strsplit(ContourFile, "_")[[1]][4], "[.]")[[1]][1], sep="")
    SpecimenID <- strsplit(ContourFile, "-")[[1]][3]
    } else {
      SpecimenName <- paste(strsplit(ContourFile, "_")[[1]][3], "_", strsplit(strsplit(ContourFile, "_")[[1]][4], "[.]")[[1]][1], sep="")
      SpecimenID <- strsplit(strsplit(ContourFile, "-")[[1]][3], "[.]")[[1]][1]
    }
    LM <- "LM=0"
    curves <- "CURVES=1"
    Contour <- read_file(ContourFile)
    Contour <- gsub("\n\n", "\n", Contour)
    Contour <- gsub("\n ", "\n", Contour)
    ContourTable <- read.delim(ContourFile)
    points <- sprintf("POINTS=%s", nrow(ContourTable))
    if (TIF==TRUE) {
      image <- paste("IMAGE=", SpecimenName, ".tif", sep="")
    } else {
      image <- paste("IMAGE=", SpecimenName, ".jpg", sep="")
    }
    ID <- sprintf("ID=%s", SpecimenID)
    scale <- sprintf("SCALE=%s", Scale)
    write(c(LM, curves, points, image, ID, scale, Contour), PopFile, ncolumns = 1, append=TRUE)
  }
}

