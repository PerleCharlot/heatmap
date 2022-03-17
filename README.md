# Heatmap

Heatmap des zones de quiétude construite à partir de données de fréquentation du territoire.

Exploitation de la [heatmap](https://www.strava.com/heatmap) de strava comme source de données de fréquentation.

## Accès aux données source, affichage et transformation

Les données sources utilisées (ici la heatmap de strava) sont publiées suivant le protocole xyz (standard de fait de diffusion web de cartes raster hiérarchiques avec des niveaux de zoom allant de 0 à 16, format popularisé par google et openstreetmap).

Les données sont fournies en projection EPSG:3857.

L'accès aux données avec un niveau de zoom > 11 (ou 10 sur les clients qui affichent les contenus en haute résolution) est réservé aux abonnés strava.
Il faut donc paramétrer le client pour qu'il n'utilise que les niveaux de zoom en accès libre.

Le format natif des données semble être png, avec une palette de 256 couleurs, chaque couleur étant définie par 3 octets RGB et un octet alpha/niveau de gris ? (valeur 0 pour NoData).

### Affichage des données source dans QGIS

Deux techniques peuvent être utilisées pour afficher les données, directement au format xyz ou via une encapsulation WMTS

#### Paramétrage xyz

Charger la connexion [QGIS/strava xyz.xml](<QGIS/strava xyz.xml>) comme une nouvelle connexion de type XYZ Tiles ( depuis l'explorateur de couches de QGIS ou depuis l'explorateur de sources de données).

La couche prédéfinie affiche toutes les activités dans la couleur hot.

Adapter la définition de couche suivant le besoin (couleur hot, purple, ... , type d'activités all, run, ride, ...).

[Lien de téléchargement](<https://raw.githubusercontent.com/PnMercantour/heatmap/master/QGIS/strava xyz.xml>)

Voir le [fichier sur github](<QGIS/strava xyz.xml>).

#### Paramétrage WMTS

L'exemple de https://opengisch.github.io/wmts/capabilities/strava.xml montre comment construire un [descripteur de flux WMTS](WMTS/strava-public.xml) qui donne accès à la heatmap de strava. La liste des niveaux de zoom a été adaptée de l'original pour ne conserver que les niveaux de zoom en accès libre.

Charger dans QGIS la connexion associée à ce flux WMTS.

[Lien de téléchargement](<https://raw.githubusercontent.com/PnMercantour/heatmap/master/QGIS/strava WMTS.xml>)

Voir le [fichier sur github](<QGIS/strava WMTS.xml>).

#### Références

https://wiki.openstreetmap.org/wiki/Strava

https://opengisch.github.io/wmts/capabilities/strava.xml

### Reprojection des données source et définition de la zone d'étude

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

L'exécution de cette commande produit le fichier `strava-25.tiff` au format GeoTiff (4 bandes, RGB et bande alpha).

`-tr 25 25` la taille donne la résolution d'un pixel, ici 25m de côté (correspond à la résolution des données source strava mesurée sur l'écran).

`-cutline ...` décrit la couche vectorielle de masquage, ici l'aire optimale totale du Parc national du Mercantour, lue depuis une base de données PostgreSQL.

`-ovr=NONE` indique de travailler avec la couche source de résolution maximale

### Exploitation du fichier GeoTiff de données de fréquentation

La taille du fichier est proportionnelle à la zone d'étude (40 lignes/colonnes par km dans chaque dimension avec la résolution de 25m). Le fichier peut si nécessaire être découpé suivant une mosaique pour en faciliter le traitement.

Le fichier peut être importé comme une couche qgis.

Les pixels sont représentés par 3 bandes RGB et une bande alpha. On utilisera dans les traitements suivants la valeur de la bande alpha qui reflète bien les différents niveaux de fréquentation.

#### Réduction du nombre de niveaux de fréquentation

La bande alpha (`-b 4`) prend une valeur nulle ou comprise 85 et 255.

On définit 4 niveaux de fréquentation de 0 à 3 par une répartition égale (visuellement, ce mode de répartition semble cohérent avec l'original couleur produit par strava). On utilise pour cela [gdal_translate](https://gdal.org/programs/gdal_translate.html)

```
gdal_translate -b 4 -scale 0 255 0 3 strava-25.tiff strava-25-rs-4.tiff
```

Au chargement de la couche, ajuster le style de la couche pour visualiser les 4 niveaux de fréquentation.

Lien de téléchargement du [style QGIS](https://raw.githubusercontent.com/PnMercantour/heatmap/master/QGIS/style_4_niveaux.qml).

#### Heatmap de quiétude

On construit un raster à 3 bandes dont les valeurs donnent la distance entre le point d'observation et le plus proche point de passage de catégorie supérieure ou égale à 1, à 2 ou 3.

On utilise au choix la boîte à outils QGIS: `GDAL - Analyse raster - Proximité` ou bien en ligne de commande le programme [gdal_proximity.py](https://gdal.org/programs/gdal_proximity.html).

```
gdal_create -of GTiff -ot UInt16 -bands 3 -if strava-25-rs-4.tiff heatmap.tiff
gdal_proximity.py -srcband 1 -dstband 1 -distunits GEO -maxdist 250 -nodata 250 -ot UInt16 -of GTiff strava-25-rs-4.tiff heatmap.tiff
gdal_proximity.py -srcband 1 -dstband 2 -values 2,3 -distunits GEO -maxdist 500 -nodata 500 -ot UInt16 -of GTiff strava-25-rs-4.tiff heatmap.tiff
gdal_proximity.py -srcband 1 -dstband 3 -values 3 -distunits GEO -maxdist 1000 -nodata 1000 -ot UInt16 -of GTiff strava-25-rs-4.tiff heatmap.tiff
```

On choisit une distance maximale au delà de laquelle la distance n'est plus significative (ici, pour l'exemple et une visualisation contrastée avec QGIS on prend 250m pour les petits sentiers, 500m pour les sentiers plus utilisés et 1000m pour les sentiers à forte fréquentation). La représentation automatique RVB de QGIS fait apparaître en blanc les zones de quiétude, en noir les zones de passage intense, et en couleur les zones de dérangement.

### Utilisation de la heatmap

Les données de distance peuvent facilement être prélevées pour enrichir une couche vectorielle de points. Voir dans QGIS le fonctionnement de l'outil `Prélèvement des valeurs rasters vers ponctuels`

_Cet algorithme crée une nouvelle couche vectorielle avec les mêmes attributs que la couche d'entrée et les valeurs rasters correspondant à l'emplacement du point.
Si la couche raster a plus d'une bande, les valeurs de toutes les bandes sont prélevées._
