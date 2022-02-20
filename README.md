# Heatmap

Reconstruction empirique d'une carte de dérangement (proximité de lieux fréquentés) à partir de données de fréquentation du territoire.

Données prises en compte pour la fréquentation : heatmap publique de strava.
https://www.strava.com/heatmap

## Accès aux données source, affichage et transformation

Les données sources utilisées (ici la heatmap de strava) sont publiées suivant le protocole xyz (standard de fait de diffusion web de cartes raster hiérarchiques avec des niveaux de zoom allant de 0 à 16, format popularisé par google et openstreetmap). Les données sont fournies en projection EPSG:3857.
L'accès aux données avec un niveau de zoom > 11 (ou 10 sur les clients qui affichent les contenus en haute résolution) est réservé aux abonnés strava.
Il faut donc paramétrer le client pour qu'il n'utilise que les niveaux de zoom autorisés (au risque d'avoir un écran blanc).

### Affichage des données source dans QGIS

Deux techniques peuvent être utilisées pour afficher les données, directement au format xyz ou via une encapsulation WMTS

#### paramétrage xyz

Charger la connexion [QGIS/strava xyz.xml](<QGIS/strava xyz.xml>) comme une nouvelle connexion de type XYZ Tiles (soit par l'explorateur de couches, soit depuis l'explorateur de sources de données). La couche prédéfinie affiche toutes les activités dans la couleur hot. Adapter la définition de couche suivant le besoin (couleur hot, purple, ... , type d'activités all, run, ride, ...).

#### paramétrage WMTS

L'exemple de https://opengisch.github.io/wmts/capabilities/strava.xml montre comment construire un descripteur de flux WMTS qui donne accès à la heatmap de strava. La liste des niveaux de zoom a été adaptée de l'original pour ne pas essayer de charger au delà du niveau de zoom ouvert au public.
Le descripteur de flux WMTS est [ici](https://raw.githubusercontent.com/PnMercantour/heatmap/master/WMTS/strava-public.xml). [Voir sur github](WMTS/strava-public.xml)

La connexion QGIS associée, à charger dans l'application, est [ici](<https://raw.githubusercontent.com/PnMercantour/heatmap/master/QGIS/strava wmts.xml>). [Voir sur github](<QGIS/strava wmts.xml>)

#### Références

https://wiki.openstreetmap.org/wiki/Strava

https://opengisch.github.io/wmts/capabilities/strava.xml

### Reprojection des données source et masquage

On doit reprojeter les données dans le SSCR RGF93/Lambert-93 (EPSG:2154) et délimiter la zone d'étude à l'aide d'une couche vectorielle. On utilise pour cela [gdalwarp](https://gdal.org/programs/gdalwarp.html).

Je ne suis pas parvenu à faire fonctionner gdalwarp depuis QGIS (menu raster/extraction/découper un raster suivant une couche de masque), j'ai dû utiliser directement le script gdal.

https://gis.stackexchange.com/questions/378922/more-efficient-processing-of-many-xyz-tiles-into-a-merged-response explique comment lire une couche xyz depuis gdal (pas testé).
J'ai utilisé le descripteur de flux WMTS pour accéder aux données.

`-tr 25 25` la taille donne la résolution d'un pixel, ici 25m de côté (correspond à la résolution des données source strava mesurée sur l'écran).

`-cutline ...` décrit la couche vectorielle de masquage, ici l'aire optimale totale du Parc national du Mercantour, lue depuis une base de données PostgreSQL.

```
gdalwarp -t_srs EPSG:2154 -of GTiff \
 -tr 25 25 -tap \
 -cutline "PG:service='projets' sslmode=verify-ca" -cl limites.limites -cwhere "nom= 'aire_optimale_totale'" -crop_to_cutline \
 -ovr NONE\
 WMTS:https://raw.githubusercontent.com/PnMercantour/heatmap/master/WMTS/strava-public.xml,layer=strava-all\
 strava-25.tiff
```
