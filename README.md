# Heatmap

Reconstruction empirique d'une carte de dérangement (proximité de lieux fréquentés) à partir de données de fréquentation du territoire.

Exploitation de la [heatmap](https://www.strava.com/heatmap) de strava comme source de données de fréquentation.

## Accès aux données source, affichage et transformation

Les données sources utilisées (ici la heatmap de strava) sont publiées suivant le protocole xyz (standard de fait de diffusion web de cartes raster hiérarchiques avec des niveaux de zoom allant de 0 à 16, format popularisé par google et openstreetmap). Les données sont fournies en projection EPSG:3857.
L'accès aux données avec un niveau de zoom > 11 (ou 10 sur les clients qui affichent les contenus en haute résolution) est réservé aux abonnés strava.
Il faut donc paramétrer le client pour qu'il n'utilise que les niveaux de zoom en accès libre (au risque d'avoir un écran blanc).

### Affichage des données source dans QGIS

Deux techniques peuvent être utilisées pour afficher les données, directement au format xyz ou via une encapsulation WMTS

#### Paramétrage xyz

Charger la connexion [QGIS/strava xyz.xml](<QGIS/strava xyz.xml>) comme une nouvelle connexion de type XYZ Tiles ( depuis l'explorateur de couches de QGIS ou depuis l'explorateur de sources de données).

La couche prédéfinie affiche toutes les activités dans la couleur hot.

Adapter la définition de couche suivant le besoin (couleur hot, purple, ... , type d'activités all, run, ride, ...).

[Lien de téléchargement](<https://raw.githubusercontent.com/PnMercantour/heatmap/master/QGIS/strava xyz.xml>))

Voir sur [github](<QGIS/strava xyz.xml>)

#### Paramétrage WMTS

L'exemple de https://opengisch.github.io/wmts/capabilities/strava.xml montre comment construire un [descripteur de flux WMTS](WMTS/strava-public.xml) qui donne accès à la heatmap de strava. La liste des niveaux de zoom a été adaptée de l'original pour ne conserver que les niveaux de zoom en accès libre.

Charger dans QGIS la connexion associée à ce flux WMTS.

[Lien de téléchargement](<https://raw.githubusercontent.com/PnMercantour/heatmap/master/QGIS/strava wmts.xml>)

Voir sur [github](<QGIS/strava wmts.xml>)

#### Références

https://wiki.openstreetmap.org/wiki/Strava

https://opengisch.github.io/wmts/capabilities/strava.xml

### Reprojection des données source et masquage

On doit reprojeter les données dans le SCR RGF93/Lambert-93 (EPSG:2154) et délimiter la zone d'étude à l'aide d'une couche vectorielle. On utilise pour cela [gdalwarp](https://gdal.org/programs/gdalwarp.html).

Je ne suis pas parvenu à faire fonctionner gdalwarp depuis QGIS (menu raster/extraction/découper un raster suivant une couche de masque), j'ai utilisé directement le script gdal.

https://gis.stackexchange.com/questions/378922/more-efficient-processing-of-many-xyz-tiles-into-a-merged-response explique comment lire une couche xyz depuis gdal (pas testé).
J'ai utilisé le descripteur de flux WMTS déjà paramétré pour accéder aux données.

```
gdalwarp -t_srs EPSG:2154 -of GTiff \
 -tr 25 25 -tap \
 -cutline "PG:service='projets' sslmode=verify-ca" \
 -cl limites.limites -cwhere "nom= 'aire_optimale_totale'" \
 -crop_to_cutline \
 -ovr NONE\
 WMTS:https://raw.githubusercontent.com/PnMercantour/heatmap/master/WMTS/strava-public.xml,layer=strava-all\
 strava-25.tiff
```

L'exécution de cette commande produit le fichier `strava-25.tiff` au format GeoTiff.

`-tr 25 25` la taille donne la résolution d'un pixel, ici 25m de côté (correspond à la résolution des données source strava mesurée sur l'écran).

`-cutline ...` décrit la couche vectorielle de masquage, ici l'aire optimale totale du Parc national du Mercantour, lue depuis une base de données PostgreSQL.

`-ovr=NONE` indique de travailler avec la couche source de résolution maximale
