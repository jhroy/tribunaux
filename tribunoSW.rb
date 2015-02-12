#!/usr/bin/env ruby
# encoding : utf-8
# ©2015 Jean-Hugues Roy. GNU GPL v3.

require "scraperwiki"
require "nokogiri"
require "open-uri"
require "twitter"

init = {
    "Numero" => "zéro",
    "Tribunal" => "cour de justice",
    "Titre" => "vide",
    "URL" => "nulle part",
    "Description" => "rien",
    "Date" => "jamais"
}

# ScraperWiki.save_sqlite(["Numero"],init,table_name="TribunauxQC") # Décommenter cette ligne la première fois que le script roule; ne pas oublier de la commenter après avoir fait fonctionner le script une première fois

# On commence par définir un hash qui joue deux rôles:
	# - donner l'URL de chaque tribunal qui nous intéresse
	# - abréger le nom de certains tribunaux, car sur Twitter, chaque caractère est compté!

rss = { 
	"de la Cour d'appel" => "http://www.canlii.org/fr/qc/qcca/rss_new.xml",
	"de la Cour supérieure" => "http://www.canlii.org/fr/qc/qccs/rss_new.xml",
	"de la Cour du Québec" => "http://www.canlii.org/fr/qc/qccq/rss_new.xml",
	"du Trib. des droits de la pers." => "http://www.canlii.org/fr/qc/qctdp/rss_new.xml",
	"du Tribunal des professions" => "http://www.canlii.org/fr/qc/qctp/rss_new.xml",
	"d'une cour municipale" => "http://www.canlii.org/fr/qc/qccm/rss_new.xml",
	"de l'Autorité des marchés fin." => "http://www.canlii.org/fr/qc/qcamf/rss_new.xml",
	"du Comité de déonto. policière" => "http://www.canlii.org/fr/qc/qccdp/rss_new.xml",
	"de la Comm. d'accès à l'info." => "http://www.canlii.org/fr/qc/qccai/rss_new.xml",
	"de la CSST" => "http://www.canlii.org/fr/qc/qccsst/rss_new.xml",
	"de la Comm. de prot. du terr. agricole" => "http://www.canlii.org/fr/qc/qccptaq/rss_new.xml",
	"de la Comm. des rel. du travail" => "http://www.canlii.org/fr/qc/qccrt/rss_new.xml",
	"de la Comm. municipale" => "http://www.canlii.org/fr/qc/qccmnq/rss_new.xml",
	"disciplinaire du Coll. des médecins" => "http://www.canlii.org/fr/qc/qccdcm/rss_new.xml",
	"disciplinaire du Barreau" => "http://www.canlii.org/fr/qc/qccdbq/rss_new.xml",
	"du Conseil de presse" => "http://www.canlii.org/fr/qc/qccpq/rss_new.xml",
	"du Tribunal adm. du Québec" => "http://www.canlii.org/fr/qc/qctaq/rss_new.xml"
}

# Fonction qui traduit les dates en français pour les afficher dans un tweet

def date(d)
	m = d[5..6]
	j = d[-2..-1]
	a = d[0..3]

	case m
		when "01"
			mm = " janv. "
		when "02"
			mm = " févr. "
		when "03"
			mm = " mars "
		when "04"
			mm = " avril "
		when "05"
			mm = " mai "
		when "06"
			mm = " juin "
		when "07"
			mm = " juil. "
		when "08"
			mm = " août "
		when "09"
			mm = " sept. "
		when "10"
			mm = " oct. "
		when "11"
			mm = " nov. "
		when "12"
			mm = " déc. "
	end

	return j + mm + a

end

# Appel de la librairie de l'API twitter et configuration pour le compte twitter du robot RoboTribunauxQC

Twitter.configure do |config| # ScraperWiki utilise une vieille version du gem twitter dont la syntaxe est différente de celle utilisée par la version de ce script qui roule en mode local
  config.consumer_key = "<entrez vos infos ici>" # Changez cette valeur et les trois suivantes pour celles que l'API de Twitter vous donnera pour votre propre compte (voir https://apps.twitter.com/)
  config.consumer_secret = "<entrez vos infos ici>"
  config.oauth_token = "<entrez vos infos ici>"
  config.oauth_token_secret = "<entrez vos infos ici>"
end

# On copie le contenu actuel des jugements dans la variable ancien

ancien = ScraperWiki.sqliteexecute("select Numero from TribunauxQC")
# puts ancien

# Boucle qui passe à travers le fil rss de chaque tribunal qui nous intéresse, un à la fois, une fois chaque heure, et qui va chercher les jugements actuellements diffusés par CanLII

rss.each do |tribunal, url|
	# puts url
	
	# On place le fil rss du tribunal dans la variable requête

	requete = Nokogiri::XML(open(url, "User-Agent" => "Jean-Hugues Roy, UQAM (roy.jean-hugues@uqam.ca)"))

    # On place le nom du tribunal dans la variable instance
    
	instance = requete.xpath("//channel/title").text
	instance = instance[instance.index(" : ")+2..-1].strip
	
	# La variable n compte le nombre de décisions contenu dans le fil rss (il y en a habituellement 20)

	n = requete.xpath("//item").count
	
	# Boucle pour aller chercher les infos de chaque décision

	(0..n-1).each do |item|

		decision = {} # Création d'un hash pour recueillir les infos de chaque décision

		decision["Numero"] = "" # Initialisation du numéro de référence de la décision, c'est la clé primaire de chaque enregistrement
		decision["Tribunal"] = instance # Nom du tribunal

		titreLong = requete.xpath("//item/title")[item].text # Titre long de la décision
		titre = requete.xpath("//item/decision:casename")[item].text # Titre complet de la décision, qu'on va raccourcir en fonction de différents critères ci-dessous (afin que ce titre puisse entrer dans les 140 car. du tweet que le robot va envoyer) 
		if titre.size > 35
			decision["Titre"] = titre[0..40] + "..."
			if titre[0..9] == "Commission"
				decision["Titre"] = "Commission " + titre[66..-1]
			elsif titre[0..15] == "Commissaire à la"
				decision["Titre"] = "CDP " + titre[39..-1]
			elsif titre[0..14] == "Médecins (Ordre"
				decision["Titre"] = "CMQ " + titre[35..-1]
			elsif titre[0..16] == "Barreau du Québec"
				if titre[19..26] == "syndique"
					decision["Titre"] = "Barreau " + titre[38..-1]
				else
					decision["Titre"] = "Barreau " + titre[35..-1]
				end
			end
		else
			decision["Titre"] = titre # Si le titre n'a pas besoin d'être raccourci, il devient le "Titre_court" quand même, car c'est la variable "Titre_court" qui sera tweetée
		end
		decision["URL"] = requete.xpath("//item/link")[item].text # URL de la décision
		decision["Description"] = requete.xpath("//item/description")[item].text # Descripteurs, ou mots-clés, relatifs au contenu de la décision
		description = ""
		if decision["Description"].size > 60 # On raccourcit la description pour la faire entrer dans un tweet
			description = decision["Description"][0..59] + "..."
		else
			description = decision["Description"]
		end
		decision["Numero"] = requete.xpath("//item/decision:neutralCitation")[item].text # Numéro de référence de la décision; si cette variable est vide, on lui attribue une valeur déterminée par CanLII
		if decision["Numero"] == ""
			decision["Numero"] = titreLong[titreLong.index(", 20")+2..-1]
		end
		decision["Date"] = requete.xpath("//item/decision:decisionDate")[item].text # Date de la décision
	
		x = 0 # Variable de contrôle: si une décision qu'on vient de scraper n'apparaît pas dans la base de données qu'on a jusqu'à maintenant, cette variable reste à zéro
        
        # On compare le numéro de référence de chaque décision à celui de toutes les décisions se trouvant pour le moment dans la base de données
        # Si la décision s'y trouve déjà, la variable x augmente de 1 (et la décision ne sera pas tweetée)
        
		ancien.each do |ancienneDecision|
			if decision["Numero"] == ancienneDecision["Numero"]
				x += 1
			end
            # puts ancienneDecision["Numero"]
		end
       
        # Si la variable x est égale à 0, c'est que nous sommes en présence d'une nouvelle décision, alors on la tweete!
        # On envoie un tweet qui nous dit de quel tribunal il s'agit, quel est le titre de la décision et son URL
            # On envoie aussi un 2e tweet avec des infos supplémentaires: numéro de décision, date et thématiques traitées par la décision
            
		if x == 0
			tweet = "Nouv. décision " + tribunal + ":\n" + decision["Titre"] + "\n" + decision["URL"]
			puts tweet
			Twitter.update(tweet)
#           puts Twitter.home_timeline[0].id
			sleep(5)
			tweet2 = "Décision " + decision["Numero"] + " rendue le " + date(decision["Date"]) + " traite de:\n" + description
# 			puts tweet2
			Twitter.update(tweet2, in_reply_to_status_id: Twitter.home_timeline[0].id)

            # On sauve la décision qu'on vient de scraper (et de tweeter) dans notre base de données
    		ScraperWiki.save_sqlite(["Numero"],decision,table_name="TribunauxQC")
    		sleep(30)
		end

	end

end
