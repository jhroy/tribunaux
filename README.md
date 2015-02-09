# tribunaux
Robot qui tweete les plus récentes décisions des tribunaux québécois en réunissant en un seul endroit [les fils RSS de CanLII](http://www.canlii.org/fr/qc/).

Incarné sur Twitter par le compte [RoboTribunauxQC](https://twitter.com/RoboTribunauxQC).

Inspiré par [BCCourtBot](https://twitter.com/BCCourtBot) de [Chad Skelton](https://github.com/chadskelton/bc-court-bot).

Comprend deux scripts:
* **tribuno.rb**: une version «locale» qui interagit avec un fichier CSV.
* **tribunoSW.rb** une version «nuage» qu'il est possible d'héberger sur [ScraperWiki](http://scraperwiki.com), par exemple, et qui interagit avec une base de données SQL.
