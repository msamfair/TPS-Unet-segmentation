args <- commandArgs(trailingOnly = TRUE)
InputFolder <- args[1]
BaseFolder <- args[2]
img <- args[3]

library(raster)
library(tiff)
library(stringr)
tps_utils_path <- paste(BaseFolder, '/tps-oo.R', sep="")
source(tps_utils_path)

# Get image file for specimen
ImagePath <- paste(InputFolder, '/', img, ".tif", sep="")
im1 <- readTIFF(ImagePath)
pixh <- dim(im1)[1]
pixw <- dim(im1)[2]

# Read in TPS file, extract xy coords of curve from specimen
species <- str_split(img,"-")[[1]][1]
pop <- str_split(img,"-")[[1]][2]
individual <- as.integer(str_split(img,"-")[[1]][3])
PopName <- paste(species, "-", pop, sep="")
TPSpath <- paste(InputFolder, '/', PopName, "-digitized.tps", sep="")
cc <- read.tps(TPSpath)
c1 <- cc[[individual]]$curve1.points
c1c <- rbind(c1, c1[1,])  # add start point to the end to close the polygon

# the important part - make a PNG file and plot curve to it
MaskPath <- paste(BaseFolder, '/Training/', img, "/masks/", img, ".png", sep="")
png(filename = MaskPath, width = pixw, height = pixh, bg = "black")
par(mai = c(0,0,0,0), xaxs = "i", yaxs = "i")
plot(c1c, typ="n", xlim=c(0, pixw), ylim=c(0, pixh))
polygon(c1c, col = "white")
dev.off()
