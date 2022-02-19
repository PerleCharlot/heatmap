https://wiki.openstreetmap.org/wiki/Strava

https://opengisch.github.io/wmts/capabilities/strava.xml

https://gdal.org/programs/gdalwarp.html

https://trac.osgeo.org/gdal/wiki/UserDocs/GdalWarp

Warping depuis qgis (raster/extraction/découper un raster suivant une couche de masque)

source couche xyz (commande gdal incorrecte, la source n'est pas reconnue)

gdalwarp -of GTiff -tr 1.0 -1.0 -tap -cutline "PG:service='mercantour' sslmode=verify-ca" -cl limregl.cr_pnm_airetotale_topo -crop_to_cutline "tilePixelRatio=1&type=xyz&url=https://heatmap-external-b.strava.com/tiles/all/hot/%7Bz%7D/%7Bx%7D/%7By%7D.png&zmax=11&zmin=11" /Users/vincent/PNM/Faune/Lièvre/Strava/retest/foo.tif

https://gis.stackexchange.com/questions/378922/more-efficient-processing-of-many-xyz-tiles-into-a-merged-response

https://gdal.org/drivers/raster/wms.html

Il faut décrire le flux xyz comme un flux WMS (et donc écrire un descripteur de flux WMS au format XML)

Avec QGIS (raster/extraction/découper un raster suivant une couche de masque):

gdalwarp -t_srs EPSG:2154 -of GTiff \
 -tr 1.0 -1.0 -tap \
 -cutline "PG:service='mercantour' sslmode=verify-ca" -cl limregl.cr_pnm_airetotale_topo -crop_to_cutline \
 "contextualWMSLegend=0&crs=EPSG:3857&dpiMode=7&featureCount=10&format=image/png&layers=strava-all&styles=strava&tileMatrixSet=google3857&url=file:////Users/vincent/PNM/Faune/Lie%CC%80vre/Strava/strava.xml" \
 /Users/vincent/PNM/Faune/Lièvre/Strava/retest/foo.tif

La commande ne fonctionne pas, gdal ne parvient pas à interpréter la description de la source.

Réécriture de la source :

ensuite on peut créer un vrt (ajouter la bande 4 transparente dans le rendu)

Niveau de précision max obtenu avec ovr=3

gdalwarp -t_srs EPSG:2154 -of GTiff \
 -tr 25 25 -tap \
 -cutline "PG:service='projets' sslmode=verify-ca" -cl limites.limites -cwhere "nom= 'aire_optimale_totale'" -crop_to_cutline \
 -ovr 3\
 WMTS:strava_public.xml,layer=strava-all\
 strava-25.tiff

Essai avec les descripteurs WMS en xml.
Le résultat affiché n'est pas identique à celui du flux xyz (reprojection?)
strava_petites_valeurs s'affiiche aux niveaux de zoom élevés.
strava_grandes_valeurs ne s'affiche pas aux niveaux de zoom élevés.
=> le niveau de zoom élevé correspond à une grande valeur -> requêtes bloquées par strava.

```xml
<TileMatrix>
                <ows:Identifier>16</ows:Identifier>
                <ScaleDenominator>8530.91833540</ScaleDenominator>
                <TopLeftCorner>-20037508.3428 20037508.3428</TopLeftCorner>
                <TileWidth>256</TileWidth>
                <TileHeight>256</TileHeight>
                <MatrixWidth>65536</MatrixWidth>
                <MatrixHeight>65536</MatrixHeight>
            </TileMatrix>
```
