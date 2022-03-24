#! /bin/sh
gdalwarp -t_srs EPSG:2154 -of GTiff \
 -tr 25 25 -tap \
 -cutline tampon_massif_alpes.shp \
 -cl tampon_massif_alpes \
 -crop_to_cutline \
 -ovr NONE\
 WMTS:https://raw.githubusercontent.com/PnMercantour/heatmap/master/WMTS/strava-public.xml,layer=strava-all \
 arcAlpin.tif