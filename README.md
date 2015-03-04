# tribunaux
Robot qui tweete les plus récentes décisions des tribunaux québécois.

Incarné sur Twitter par le compte [RoboTribunauxQC](https://twitter.com/RoboTribunauxQC). 
Inspiré par [BCCourtBot](https://twitter.com/BCCourtBot) de [Chad Skelton](https://github.com/chadskelton/bc-court-bot).

Dès qu'une décision est disponible, deux tweets sont envoyés:

Le **premier tweet** comprend le nom de la décision, ainsi qu'un URL vers le texte du jugement.

Le **second tweet** comprend la date et quelques mots-clés ou thèmes abordés par le jugement.

Les jugements sont tweetés quelques jours après qu'ils aient été rendus. Cela est normal puisque ce robot puise dans les [fils RSS de l'Institut canadien d'information juridique](http://www.canlii.org/fr/qc/).

Comprend deux scripts:
* **tribuno.rb**: une version «locale» qui interagit avec un fichier CSV.
* **tribunoSW.rb** une version «nuage» qu'il est possible d'héberger sur [ScraperWiki](http://scraperwiki.com), par exemple, et qui interagit avec une base de données SQL.

Les 17 tribunaux inclus (judiciaires, administratifs, disciplinaires et d'honneur):
* Cour d'appel
* Cour supérieure
* Cour du Québec
* Tribunal des droits de la personne
* Tribunal des professions
* Cours municipales
* Autorité des marchés financiers
* Comité de déontologie policière
* Commission d'accès à l'information
* Commission de la santé et de la sécurité au travail (CSST)
* Commission de protection du territoire agricole
* Commission des relations du travail
* Commission municipale
* Conseil de discipline du Collège des médecins
* Conseil de discipline du Barreau
* Conseil de presse
* Tribunal administratif du Québec
