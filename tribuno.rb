#!/usr/bin/env ruby
# encoding : utf-8
# ©2015 Jean-Hugues Roy. GNU GPL v3.

require "Nokogiri"
require "open-uri"
require "csv"
require "twitter"

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
	"de la Comm. des rel. du travail" => "http://www.canlii.org/fr/qc/qccptaq/rss_new.xml",
	"de la Comm. municipale" => "http://www.canlii.org/fr/qc/qccmnq/rss_new.xml",
	"disciplinaire du Coll. des médecins" => "http://www.canlii.org/fr/qc/qccdcm/rss_new.xml",
	"disciplinaire du Barreau" => "http://www.canlii.org/fr/qc/qccdbq/rss_new.xml",
	"du Conseil de presse" => "http://www.canlii.org/fr/qc/qccpq/rss_new.xml",
	"du Cons. des serv. essentiels" => "http://www.canlii.org/fr/qc/qccse/rss_new.xml",
	"du Tribunal adm. du Québec" => "http://www.canlii.org/fr/qc/qctaq/rss_new.xml"
}

# Initialisation de certaines variables

tout = []
ancien = []
i = 0

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

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = "SNOpxca1d3jRJaGi9k9cO44Ls"
  config.consumer_secret     = "CPfyAUyssWdHiqVSubBj9Tnn1p4ZJ9Mzw4rtgOtB3ZtKiMC51t"
  config.access_token        = "3018688025-xz4fZElQM5xkmpAFpWSQUf8k7fT37Hn8NtXHS4f"
  config.access_token_secret = "7U5ROVIOOvHXwxbHsSurYvlOWGB7hpLTkNppenKsYUDGh"
end

# Lecture des décisions précédentes dans un tableau

ancien = CSV.read("tribunaux.csv", headers:true)

rss.each do |tribunal, url|
	# puts url

	requete = Nokogiri::XML(open(url, "User-Agent" => "Jean-Hugues Roy, UQAM (roy.jean-hugues@uqam.ca)"))

	instance = requete.xpath("//channel/title").text
	instance = instance[instance.index(" : ")+2..-1].strip

	n = requete.xpath("//item").count

	(0..n-1).each do |item|

		i += 1

		decision = {}

		decision["id"] = i
		decision["Numero"] = ""
		decision["Tribunal"] = instance

		decision["Titre_long"] = requete.xpath("//item/title")[item].text
		decision["Titre"] = requete.xpath("//item/decision:casename")[item].text
		if decision["Titre"].size > 35
			decision["Titre_court"] = decision["Titre"][0..35] + "..."
			if decision["Titre"][0..9] == "Commission"
				decision["Titre_court"] = "Commission " + decision["Titre"][66..-1]
			elsif decision["Titre"][0..15] == "Commissaire à la"
				decision["Titre_court"] = "CDP " + decision["Titre"][39..-1]
			elsif decision["Titre"][0..14] == "Médecins (Ordre"
				decision["Titre_court"] = "CMQ " + decision["Titre"][35..-1]
			elsif decision["Titre"][0..16] == "Barreau du Québec"
				if decision["Titre"][19..26] == "syndique"
					decision["Titre_court"] = "Barreau " + decision["Titre"][38..-1]
				else
					decision["Titre_court"] = "Barreau " + decision["Titre"][35..-1]
				end
			end
		else
			decision["Titre_court"] = decision["Titre"]
		end
		decision["URL"] = requete.xpath("//item/link")[item].text
		decision["Description"] = requete.xpath("//item/description")[item].text
		description = ""
		if decision["Description"].size > 60 # On raccourcit la description pour la faire entrer dans un tweet
			description = decision["Description"][0..59] + "..."
		else
			description = decision["Description"]
		end
		# puts description
		decision["Numero"] = requete.xpath("//item/decision:neutralCitation")[item].text
		if decision["Numero"] == ""
			decision["Numero"] = decision["Titre_long"][decision["Titre_long"].index(", 20")+2..-1]
		end
		decision["Date_de_decision"] = requete.xpath("//item/decision:decisionDate")[item].text
		decision["Date_de_modification"] = requete.xpath("//item/decision:lastModified")[item].text

		x = 0

		ancien.each do |ancienneDecision|
			if decision["Numero"] == ancienneDecision[1]
				x += 1
			end
		end

		if x == 0
			tweet = "Nouv. décision " + tribunal + ": " + decision["Titre_court"] + "\n" + decision["URL"]
			puts tweet # affichage du tweet aux fins de vérification
			client.update(tweet)
			sleep 5 # On laisse à Twitter le temps de se remettre de l'envoi d'un premier tweet
			tweet2 = "@RoboTribunauxQC\nLa décision " + decision["Numero"] + " rendue le " + date(decision["Date_de_decision"]) + "\ntraite de:\n" + description
			puts tweet2 # affichage aux fins de vérification
			# puts client.home_timeline[0].id
			client.update(tweet2, in_reply_to_status: client.home_timeline[0])
		end

		tout.push decision

	end

end

# puts tout

CSV.open("tribunaux.csv", "wb") do |csv|
  csv << tout.first.keys
  tout.each do |hash|
    csv << hash.values
  end
end
