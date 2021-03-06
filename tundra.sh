#!/bin/sh
# tundra.sh v1.0

########## Configuration ###########
AUTHOR="frainfreeze"
BLOG_TITLE="frainfreeze's example blog for tundra.sh"

ROOT=`pwd`
INDEX_PATH=README.md
INDEX_RES=res

POSTS_PATH=posts
POSTS_RES=../res

PAGES_PATH=pages
PAGES_RES=../res

# MD_FLAVOUR tells pandoc what markdown flavour to use,
# +yaml_met... turns on yaml meta data option in pandoc
MD_FLAVOUR="markdown_github+yaml_metadata_block"


######### Implementation ##########
AWK=`which gawk || which awk`
SED=`which gsed || which sed`

usage() {
    echo "Static site generator using pandoc."
    echo "./tundra.sh"
    echo "   -h --help \tDisplays this page."
    echo "   -i --index \tDefine custom index file and build."
    echo "   -b --build \tGenerates HTML from the sources."
    echo "   -c --clean \tDeletes HTML files"
    echo ""
}

gen_archive(){
    echo "Generating archive"
    cd $POSTS_PATH
    cat $ROOT/res/blog-index.Thtml > index.html

    echo "<h2>Blog archive</h2>" >> index.html
    echo "<input class=\"button-shadow\" type=\"button\" id=\"test\" value=\"sort by date\"/>" >> index.html
    echo "<input class=\"button-shadow\" type=\"button\" id=\"test1\" value=\"sort by title\"/>" >> index.html
    echo "<ul id=\"list\">" >> index.html

    for url in *.html; do
        if [ "$url" != "index.html" ]
        then
            title=`$AWK -vRS="</title>" '/<title>/{gsub(/.*<title>|\n+/,"");print;exit}' $url`
           date=`cat $url | $SED -rn "/<meta .*name=.date./ s/.*content=.([0-9-]+).*/\1/p"`
            echo "<li><span class=\"date\">$date</span> - <a href=\"$url\"><span class="post-title">$title</span></a></li>" >> index.html
        fi
    done

    echo "</ul></body></html>" >> index.html
    $SED -i "s/blog-title/$BLOG_TITLE/g" index.html

    cd $ROOT
}

build_sources() {
    echo "Building sources..."
    START_TIME=$(date +%s)
    
    # build index
    if [ ! -z ${INDEX_PATH+x} ]; 
    then
        echo "\tBuilding index"
        pandoc -f $MD_FLAVOUR $INDEX_PATH -o "index.html" --template $INDEX_RES/index.Thtml --css=$INDEX_RES/style.css
    fi

    # build blog
    if [ ! -z ${POSTS_PATH+x} ]; 
    then
        echo "\tBuilding blog"
        
        cd $POSTS_PATH
        
        for f in *.md; do 
            pandoc -f $MD_FLAVOUR "$f" -s -o "${f%.*}.html" --template $POSTS_RES/blog.Thtml --css=$POSTS_RES/style.css
        done
        
        cd $ROOT
        gen_archive
    fi

    # build static pages
    if [ ! -z ${PAGES_PATH+x} ]; 
    then
        echo "\tBuilding static pages"
        cd $PAGES_PATH
        for page in *.md;
        do
            pandoc -f $MD_FLAVOUR $page -o "${page%.*}.html" --template $PAGES_RES/index.Thtml --css=$PAGES_RES/style.css
        done
        cd $ROOT
    fi

    END_TIME=$(($(date +%s) - $START_TIME))
    echo "Sources built in $(($END_TIME/60)) min $(($END_TIME%60)) sec" 
}

if [ -z "$1" ] 
then
  usage
  exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
        -h | --help)
            usage
            exit 0
            ;;
        -i | --index)
            if [ "$2" != "" ]; then
                INDEX_PATH=$2
                build_sources
            else
                echo "You must specify index file when using -i/--index!"
            fi
            exit 0
            ;;
        -b | --build)
            build_sources
            exit 0
            ;;
        -c | --clean)
            find . -type f -iname "*.html" -delete
            echo "Deleted all html files!"
            exit 0
            ;;
        *)
            echo "ERROR: unknown parameter \"$1\""
            usage
            exit 1
            ;;
    esac
    shift
done
