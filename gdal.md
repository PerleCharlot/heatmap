https://gdal.org/programs/gdalwarp.html

https://trac.osgeo.org/gdal/wiki/UserDocs/GdalWarp

https://gdal.org/drivers/raster/wmts.html#raster-wmts

https://gis.stackexchange.com/questions/292882/wmts-is-working-with-256x256-tiles-but-not-with-512x512

```
gdalwarp -dstnodata 255 -co COMPRESS=DEFLATE -of GTiff -r lanczos -crop_to_cutline -cutline sample_area.json wmts.xml clipped_region.tif

gdalwrap -of GTiff -crop_to_cutline -cutline test/cutline.shp -ovr 8 strava.xml foo.tif

gdalwarp -s_srs EPSG:3857 -of GTiff -crop_to_cutline -cutline test/cutline.shp -ovr 8 strava.xml foo.tif

gdalinfo WMTS:strava.xml,layer=strava-all

gdalwarp -s_srs EPSG:3857 -if WMTS -of GTiff -crop_to_cutline -cutline test/cutline.shp -ovr 12 strava.xml strava12.tif

gdalwarp -of GTiff -crop_to_cutline -cutline test/cutline.shp -ovr 8 WMTS:strava.xml,layer=strava-all foo.tif

gdalwarp -of GTiff -crop_to_cutline -cutline test/cutline.shp  WMTS:strava_public.xml,layer=strava-ride strava-ride.tif

clip
Extent: (749013.634937, 5467641.112522) - (791575.695126, 5522067.051036)

gdal_translate -projwin 749013 5522067 791575  5467641 WMTS:strava_public.xml,layer=strava-ride strava-ride.tif


Création d'un fichier tif, pour les tuiles incluses ou intersectant la boîte projwin.
gdal_translate -projwin 749013 5522067 791575  5467641 WMTS:strava_public.xml,layer=strava-run strava-tile.tif -co "TILED=YES"



https://github.com/OSGeo/gdal/issues/2052
gdalwmscache : répertoire cache des réponses curl.
CPL_CURL_VERBOSE=YES pour obtenir les logs de curl
GDAL_HTTP_HEADER_FILE=/tmp/header.txt pour ajouter des cookies à la requête.
```
