"""
Applet: Le Mot du Jour
Summary: Shows FrenchPod101's French Word of the Day
Description: Displays the French Word of the Day from FrenchPod101.
Author: mlttanaka
"""

load("render.star", "render")
load("http.star", "http")
load("html.star", "html")
load("cache.star", "cache")
load("encoding/json.star", "json")

LE_MOT_DU_JOUR_URL = "https://www.frenchpod101.com/french-phrases/"
CACHE_KEY = "lmdj"
CACHE_TTL = 10800  # 3 hours

def start_pretty():
    # Pretty lines to indicate the code is running and make
    # the terminal output more readable when debugging.
    
    print("* ------------------------------------------------------ *")
    print("* Starting app:  Le Mot du Jour")

def format_classe(ugly_string):
    # Remove white space and parentheses from an ugly string, and
    # if the cleaned string contains more than one word,
    # return the cleaned string in reversed word order separated
    # by a space. Otherwise, just return the cleaned string.
    
    cleaned_string = ugly_string.strip().replace("(", "").replace(")", "").split()
    if len(cleaned_string) > 1:
        start = len(cleaned_string) - 1
        reversed_word_order = [cleaned_string[i] for i in range(start, -1, -1)]
    
        return " ".join(reversed_word_order)
    else:
        return " ".join(cleaned_string)



def main():
    start_pretty()

    cached_dict = cache.get(CACHE_KEY)

    if cached_dict != None:
        print("* I already have some data in the cache. Let's use it, shall we?")

        lmdj_dict = json.decode(cached_dict)

        mot_francais = lmdj_dict["mot_francais"]
        mot_anglais = lmdj_dict["mot_anglais"]
        classe_de_mot = lmdj_dict["classe_de_mot"]
    else:
        print("* My data cache is empty!! Gonna get some fresh data.")

        reponse = http.get(LE_MOT_DU_JOUR_URL)

        if reponse.status_code != 200:
            fail("Le Mot du Jour request failed with status %d", reponse.status_code)

        corps = html(reponse.body())
        
        mot_francais = corps.find(".r101-wotd-widget__word").first().text()
        if mot_francais == "":
            fail("Failed to find French word from web page")
        mot_anglais = corps.find(".r101-wotd-widget__english").first().text()
        classe_de_mot = format_classe(
            corps.find(".r101-wotd-widget__class").first().text()
            )

        lmdj_json = json.encode({
            "mot_francais": mot_francais,
            "mot_anglais": mot_anglais,
            "classe_de_mot": classe_de_mot
        })

        cache.set(CACHE_KEY, lmdj_json, CACHE_TTL)

    print("* Le mot du jour est, \"%s\"." % mot_francais)
    print("* The English translation is, \"%s\"." % mot_anglais)
    print("* Class of word: \"%s\"" % classe_de_mot)


    return render.Root(
        render.Column(
            cross_align="start",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Box(
                            width = 21,
                            height = 8,
                            color = "#0055A4",
                            child = render.Text("MOT")
                        ),
                        render.Box(
                            width = 22,
                            height = 8,
                            color = "#fff",
                            child = render.Text("DU", color = "#555")
                        ),
                        render.Box(
                            width = 21,
                            height = 8,
                            color = "#EF4135",
                            child = render.Text("JOUR")
                        )
                    ]
                ),
                render.Padding(
                    pad = (1, 0, 1, 0),
                    child = render.Marquee(
                        render.Column(
                            children = [ 
                                render.WrappedText(
                                    content = mot_francais,
                                    color = "#D2691E",
                                    font = "6x13",
                                ),
                                render.WrappedText(
                                    content = mot_anglais,
                                    color = "#33b5e5",
                                    font= "tom-thumb"
                                ),
                                render.WrappedText(
                                    content = classe_de_mot,
                                    color = "#666",
                                    font= "tom-thumb"
                                )
                            ]
                        ),
                        height = 26,
                        offset_start = 0,
                        offset_end = 0,
                        scroll_direction = "vertical",
                    )
                )
            ]
        )
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )