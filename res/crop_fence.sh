for i in {1..4}; do
  convert fence_${i}_side.png -crop 197x284+0+0 fence_${i}_side_upper.png
  convert fence_${i}_side.png -crop 197x270+0+284 fence_${i}_side_lower.png
done
