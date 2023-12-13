for f in `find . -name "*.jpg"`
do
    convert $f -resize 64x64  $f_retro.png
done
