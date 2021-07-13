for i in {1..4}; do
  convert fence_${i}_side.png -crop 197x284+0+0 ../sprites/fence_${i}_side_upper.png
  convert fence_${i}_side.png -crop 197x270+0+284 ../sprites/fence_${i}_side_lower.png
done

for i in dog_*.png; do
  convert $i -scale 87.5% ../sprites/$i
done

for i in bubble_*.png *_mark.png; do
  convert $i -scale 75% ../sprites/$i
done

for i in sheep_*.png; do
  convert $i -scale 50% ../sprites/$i
done

for i in flowers_*.png; do
  convert $i -scale 50% ../sprites/$i
done

for i in bush_*.png; do
  convert $i -scale 37.5% ../sprites/$i
done

for i in game_start.png; do
  convert $i -scale 50% ../background/$i
done

convert background.png -crop 2160x1000+0+0 -scale 25% ../background/background_upperleft.png
convert background.png -crop 1800x1000+2200+0 -scale 25% ../background/background_upperright.png
convert background.png -crop 4000x3000+0+1000 -scale 25% ../background/background_lower.png
