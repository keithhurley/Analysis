# Derived copies of the Chapter 5 profile images (prompt 126, D167-D168).
# The originals in angler_profile_pictures/ and angler_profile_icons/ are
# never modified. Run by hand when an original changes; the report only reads
# the derived files and stops if any is missing.

library(magick)

src_photo_dir <- "angler_profile_pictures"
src_icon_dir <- "angler_profile_icons"
out_dir <- "angler_profile_images_derived"
n_classes <- 6

dir.create(out_dir, showWarnings = FALSE)

# Photos: 2816 px wide originals are ~3 MB each; 1600 px is ample for a 6.5 in
# figure and keeps the tracked docx small.
for (k in seq_len(n_classes)) {
  image_read(file.path(src_photo_dir, paste0("class", k, ".jpg"))) |>
    image_resize("1600x") |>
    image_write(
      file.path(out_dir, paste0("class", k, "_photo.jpg")),
      quality = 85
    )
}

# Icons: every icon gets the same treatment so all six match in a table.
# Near-white pixels go to pure white (removes the class 5 paper texture), the
# outer frame is shaved off (removes the class 4 border), then each glyph is
# trimmed and re-centred on a square with an equal margin.
for (k in seq_len(n_classes)) {
  img <- image_read(file.path(src_icon_dir, paste0("class", k, ".jpg"))) |>
    image_convert(colorspace = "gray") |>
    image_threshold(type = "white", threshold = "75%")
  info <- image_info(img)
  img <- img |>
    image_crop(paste0(info$width - 80, "x", info$height - 80, "+40+40")) |>
    image_trim(fuzz = 10)
  side <- max(image_info(img)$width, image_info(img)$height)
  img |>
    image_extent(
      paste0(side, "x", side),
      gravity = "center",
      color = "white"
    ) |>
    image_border(
      "white",
      paste0(round(side * 0.06), "x", round(side * 0.06))
    ) |>
    image_resize("300x300") |>
    image_write(
      file.path(out_dir, paste0("class", k, "_icon.png")),
      format = "png"
    )
}

stopifnot(
  length(list.files(out_dir, "_photo\\.jpg$")) == n_classes,
  length(list.files(out_dir, "_icon\\.png$")) == n_classes
)
