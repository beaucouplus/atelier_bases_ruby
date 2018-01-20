# On require la gem qui nous permet de communiquer avec twitter
require 'twitter'

# on met ses clés dans un fichier externe pour ne pas se les faire piquer
# Et on ne les met pas sur github

# on encapsule la requête twitter dans une fonction parce qu'on est fainéant.
def query_twitter
  # on appelle le fichier qui contient les clés d'identification
  require_relative 'auth'

  # on se connecte à l'api
  Twitter::REST::Client.new do |config|
    config.consumer_key        = MY_CONSUMER_KEY
    config.consumer_secret     = MY_CONSUMER_SECRET
    config.access_token        = MY_ACCESS_TOKEN
    config.access_token_secret = MY_ACCESS_TOKEN_SECRET
  end
end

# On crée une fonction pour chercher les emails sur twitter.
# Cette fonction va devoir :
# 1 - récupérer des tweets contenant les mots clés "email" et "@" en excluant les RT
# 2 - identifier et isoler les tweets contenant un véritable e-mail
# 3 - les mettre dans un tableau

def search_emails
  # on enregistre ce que nous retourne la fonction query_twitter dans une variable
  client = query_twitter

  # on fait la recherche à partir de cette variable.
  tweets = client.search("\@ -RT email", result_type: "recent").take(200)
  # Note : ça marcherait tout aussi bien comme ça, en appelant directement la fonction.
  # query_twitter.search("\@ -RT email", result_type: "recent").take(200)

  # on récupère les emails au sein de notre recherche twitter.
  # Etant donné que la recherche twitter nous renvoie un tableau, on doit agir sur ce tableau.

  # J'ai créé 3 fonction différentes qui donnent le même résultat de 3 manières différentes.
  # Vous les trouverez définies (et expliquées) plus bas dans le programme.
  # Décommentez celle que vous voulez essayer et commentez les 2 autres :)

  # transform_array_with_each(tweets)
  # transform_array_with_map(tweets)
  transform_array_with_each_with_object(tweets)

end


# Version #1 avec "each"
def transform_array_with_each(array)
  # On crée un tableau avant de faire l'itération.
  # On itère sur le tableau. Notez qu'il s'appelle "array" étant donné que c'est le paramètre
  # de la fonction.
  # On détecte les emails grâce au regex.
  # On élimine les cases vides grâce à la condition (ici unless).
  # On intègre les résultats au tableau.
  # On retourne le tableau results désormais rempli.
  # Notez qu'il faut le retourner sinon la fonction
  # renvoie la variable tweets.

  results = []
  array.each do |tweet|
    email = "#{tweet.text}".match(/\w+\.?\+?\w+?@\w+\-?\w+\.\w+/)
    results << email.to_s unless email == nil
  end
  results
end

# Version #2 avec "map", puis "compact" puis "uniq"
def transform_array_with_map(array)
  # Avec la fonction map, on transforme le tableau appelé grâce au paramètre array.
  # Au début, le tableau renvoie ça : [#<Twitter::Tweet id=954654232795283457>, ...]
  # On applique le regex puis on s'assure que les emails soient renvoyés en tant que string.

  # La fonction map renvoie ça : [email@quelquechose.com,nil,nil,autreemail@bs.com,...]
  # Ensuite, on applique la fonction compact, qui élimine les valeurs nil du tableau.
  # Enfin, on élimine les potentiels doublons avec la fonction uniq.
  array.map do |tweet|
    result = "#{tweet.text}".match(/\w+\.?\+?\w+?@\w+\-?\w+\.\w+/)
    result.to_s unless result == nil
  end.compact.uniq
end

# Version #3 avec "each_with_object" puis "uniq"
def transform_array_with_each_with_object(array)
  # Merci à Zaratan pour ce code. Vous noterez qu'il a modifié la façon
  # dont on exclue nil : (if email) = (unless email == nil ).

  # Avec la fonction each_with_object,
  # on crée un tableau en même temps qu'on itère sur l'objet.
  # le [] dans la parenthèse signifie qu'on crée un tableau vide.
  # Le second paramètre après le do : "results" est le nom donné au tableau.
  # On applique comme d'habitude le regex.
  # Et on l'enregistre dans le tableau "results" qu'on vient de nommer.
  # On applique .uniq pour supprimer les doublons dans le tableau.
  array.each_with_object([]) do |tweet, results|
    email = "#{tweet.text}".match(/\w+\.?\+?\w+?@\w+\-?\w+\.\w+/)
    puts email
    results << email.to_s if email
  end.uniq
end

# On crée une fonction qui va empêcher d'enregistrer plusieurs fois le même email
# Cette fonction  va lire le contenu du fichier tweets.txt et le comparer au tableau
# que nous a renvoyé la fonction précédente
def delete_doubles(param)
  emails = param
  # On enregistre le contenu actuel du fichier tweets.txt dans un tableau,
  # après avoir enlevé les "\n" (retours à la ligne) grâce à .chomp
  saved_emails = File.readlines("tweets.txt").map { |email| email.chomp }

  # On soustrait cette liste d'emails au tableau de tweets renvoyé
  # par la fonction search_emails pour ne pas avoir de doublons.
  # Une soustraction de tableaux fonctionne comme ça :
  # [1,2,3] - [2,3] = [1]
  emails = emails - saved_emails
end


# On crée la fonction qui enregistrera les emails dans un fichier texte
# Cette fonction va aussi :
# compter le nombre d'emails ajoutés
# Afficher les emails

def save_emails
  # on crée un compteur à zéro
  counter = 0

  # On appelle la fonction delete_doubles pour enlever les doublons.
  # Notez qu'on met directement en paramètre la fonction "search_emails",
  # parce que cette fonction renvoie le tableau dont on a besoin
  emails = delete_doubles(search_emails)

  #on itère sur le tableau dédoublonné pour enregistrer les emails dans le fichier.
  emails.each do |email|
    # On incrémente le compteur "counter".
    # Notez le "+=" qui est l'équivalent de counter = counter + 1
    counter += 1
    # On enregistre les tweets dans le fichier.
    # Notez le 'a' qui permet de faire 'append' sur le fichier.
    # Cela veut dire qu'on ajoute au fichier, sans modifier ou supprimer
    # ce qui était présent auparavant.
    # Notez aussi le "\n" qui permet de passer à la ligne. C'est cosmétique uniquement,
    # pour que le fichier soit lisible.
    File.open("tweets.txt", 'a'){|file| file.write(email + "\n")}
  end

  # on affiche le nombre de fichiers ajoutés au fichier
  puts "#{counter} files added to the file"
end

save_emails
