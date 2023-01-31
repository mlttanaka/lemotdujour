"""
Applet: Le Mot du Jour
Summary: Shows FeedBlitz's French Word of the Day
Description: Displays the French Word of the Day from FeedBlitz.
Author: mlttanaka
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

LE_MOT_DU_JOUR_URL = "https://feeds.feedblitz.com/french-word-of-the-day&x=1"
CACHE_KEY = "lmdj"
CACHE_TTL = 10800  # 3 hours


def start_pretty():
    # Add decorative lines and title to make output readable for humans.

    print("+-------------------------+")
    print("| Running: Le Mot du Jour |")
    print("+-------------------------+")

def strip_article(mot):
    # Strips the article from the word.
    return mot.removeprefix("le ").removeprefix("la ")

def scale_font(mot):
    # Use a smaller font if the word contains too many characters
    # to fit nicely in the display.
    if len(mot) >= 12:
        return "5x8"
    return "Dina_r400-6"


def main():
    start_pretty()

    cached_dict = cache.get(CACHE_KEY)

    if cached_dict != None:
        print("Using cached data...")

        lmdj_dict = json.decode(cached_dict)

        mot_francais = lmdj_dict["mot_francais"]
        mot_anglais = lmdj_dict["mot_anglais"]
        classe_de_mot = lmdj_dict["classe_de_mot"]
    else:
        print("Fetching new data...")

        reponse = http.get(LE_MOT_DU_JOUR_URL)

        if reponse.status_code != 200:
            fail("Le Mot du Jour request failed with status %d", reponse.status_code)

        content = reponse.body()

        xml = xpath.loads(content)
        cdata = xml.query_all("//title")
        sommat, mot_anglais= str(cdata[1]).split(": ")
        mot_francais = strip_article(sommat)
        nested_cdata = xml.query_all("//description")
        xml = xpath.loads(nested_cdata[1])
        classe_de_mot, example_francais, example_anglais = xml.query_all("//td")

        lmdj_json = json.encode({
            "mot_francais": mot_francais,
            "mot_anglais": mot_anglais,
            "classe_de_mot": classe_de_mot,
        })

        cache.set(CACHE_KEY, lmdj_json, CACHE_TTL)

    print("Le mot du jour est, \"%s.\"" % mot_francais)
    print("In English this means, \"%s.\"" % mot_anglais)
    print("It's this class of word: %s" % classe_de_mot)

    # TODO Squeeze the sample sentences below onto the display later.
    print("Sample sentence en Français: %s" % example_francais) 
    print("Sample sentence in English: %s" % example_anglais) 

    return render.Root(
        delay = 90,
        child = render.Column(
            cross_align = "space_evenly",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Box(
                            width = 22,
                            height = 8,
                            color = "#0055A4",
                            child = render.Text("MOT"),
                        ),
                        render.Box(
                            width = 20,
                            height = 8,
                            color = "#fff",
                            child = render.Text("DU", color = "#555"),
                        ),
                        render.Box(
                            width = 22,
                            height = 8,
                            color = "#EF4135",
                            child = render.Text("JOUR"),
                        ),
                    ],
                ),
                render.Padding(
                    pad = 1,
                    child = render.Marquee(
                        height = 24, 
                        offset_start = 24,
                        offset_end = 24,
                        scroll_direction = "vertical",
                        child = render.Column(
                            main_align = "space_evenly",
                            children = [
                                render.WrappedText(
                                    content = mot_francais,
                                    color = "#D2691E",
                                    font = scale_font(mot_francais),
                                ),
                                render.Text(
                                    content = mot_anglais,
                                    color = "#33b5e5",
                                    font = "tom-thumb",
                                ),
                                render.Text(
                                    content = classe_de_mot,
                                    color = "#666",
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
