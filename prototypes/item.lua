data:extend(
{
  {
    type = "selection-tool",
    name = "copy-blueprint",
    icon = "__CutAndCopyBlueprint__/graphics/icons/copy-blueprint.png",
    flags = {"goes-to-quickbar"},
    subgroup = "tool",
    order = "c[automated-construction]-b[copy-blueprint]",
    stack_size = 1,
    stackable = false,
    selection_color = { r = 0, g = 1, b = 0 },
    alt_selection_color = { r = 1, g = 1, b = 0 },
    selection_mode = {"blueprint"},
    alt_selection_mode = {"blueprint"},
    selection_cursor_box_type = "copy",
    alt_selection_cursor_box_type = "not-allowed",
  },
  {
    type = "recipe",
    name = "copy-blueprint",
    enabled = "true",
    ingredients = {},
    result = "copy-blueprint",
  },
  
  {
    type = "selection-tool",
    name = "cut-blueprint",
    icon = "__CutAndCopyBlueprint__/graphics/icons/cut-blueprint.png",
    flags = {"goes-to-quickbar"},
    subgroup = "tool",
    order = "c[automated-construction]-b[cut-blueprint]",
    stack_size = 1,
    stackable = false,
    selection_color = { r = 1, g = 1, b = 0 },
    alt_selection_color = { r = 0, g = 1, b = 0 },
    selection_mode = {"blueprint"},
    alt_selection_mode = {"blueprint"},
    selection_cursor_box_type = "not-allowed",
    alt_selection_cursor_box_type = "copy",
  },
  {
    type = "recipe",
    name = "cut-blueprint",
    enabled = "true",
    ingredients = {},
    result = "cut-blueprint",
  }
}
)
