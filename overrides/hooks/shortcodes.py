import posixpath
import re

from mkdocs.config.defaults import MkDocsConfig
from mkdocs.structure.files import File, Files
from mkdocs.structure.pages import Page
from re import Match

# -----------------------------------------------------------------------------
# Hooks
# -----------------------------------------------------------------------------

def on_page_markdown(
    markdown: str, *, page: Page, config: MkDocsConfig, files: Files
):
    # Replace callback
    def replace(match: Match):
        type, args = match.groups()
        args = args.strip()
        
        if type == "version":    return _badge_for_version(args, page, files)
        elif type == "feature":  return _badge_for_feature(args, page, files)
        elif type == "plugin":   return _badge_for_plugin(args, page, files)
        elif type == "default":  return _badge_for_default(args, page, files)
        elif type == "flag":     return flag(args, page, files)
        elif type == "experimental": return _badge_for_experimental(page, files)

        # Fallback for unknown shortcodes (optional, or raise error)
        return match.group(0)

    # Find and replace all external asset URLs in current page
    return re.sub(
        r"<!-- md:(\w+)(.*?) -->",
        replace, markdown, flags = re.I | re.M
    )

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

# Create a flag of a specific type
def flag(args: str, page: Page, files: Files):
    type, *_ = args.split(" ", 1)
    if   type == "experimental":  return _badge_for_experimental(page, files)
    # Add other flags here if needed (e.g. required, customization)
    return ""

# -----------------------------------------------------------------------------

# Resolve path of file relative to given page
def _resolve_path(path: str, page: Page, files: Files):
    path, anchor, *_ = f"{path}#".split("#")
    path = _resolve(files.get_file_from_path(path), page)
    return "#".join([path, anchor]) if anchor else path

# Resolve path of file relative to given page
def _resolve(file: File, page: Page):
    if not file: return "#" # Safety check if file not found
    path = posixpath.relpath(file.src_uri, page.file.src_uri)
    return posixpath.sep.join(path.split(posixpath.sep)[1:])

# -----------------------------------------------------------------------------

# Create badge
def _badge(icon: str, text: str = "", type: str = ""):
    classes = f"mdx-badge mdx-badge--{type}" if type else "mdx-badge"
    return "".join([
        f"<span class=\"{classes}\">",
        *([f"<span class=\"mdx-badge__icon\">{icon}</span>"] if icon else []),
        *([f"<span class=\"mdx-badge__text\">{text}</span>"] if text else []),
        f"</span>",
    ])

# -----------------------------------------------------------------------------
# Specific Badge Logic (Adapted for Mach-V)
# -----------------------------------------------------------------------------

# Create badge for version
def _badge_for_version(text: str, page: Page, files: Files):
    spec = text
    # Path to your changelog file
    path = f"sw/changelog/index.md#{spec}" 

    # Return badge
    icon = "material-tag-outline"
    # Path to your conventions file anchor
    href = _resolve_path("sw/changelog/conventions.md#version", page, files)
    return _badge(
        icon = f"[:{icon}:]({href} 'Minimum version')",
        text = f"[{text}]({_resolve_path(path, page, files)})" if spec else ""
    )

# Create badge for feature
def _badge_for_feature(text: str, page: Page, files: Files):
    icon = "material-toggle-switch"
    href = _resolve_path("sw/changelog/conventions.md#feature", page, files)
    return _badge(
        icon = f"[:{icon}:]({href} 'Optional feature')",
        text = text
    )

# Create badge for plugin
def _badge_for_plugin(text: str, page: Page, files: Files):
    icon = "material-floppy" # or material-chip
    href = _resolve_path("sw/changelog/conventions.md#plugin", page, files)
    return _badge(
        icon = f"[:{icon}:]({href} 'External IP / Plugin')",
        text = text
    )

# Create badge for default value
def _badge_for_default(text: str, page: Page, files: Files):
    icon = "material-water"
    href = _resolve_path("sw/changelog/conventions.md#default", page, files)
    return _badge(
        icon = f"[:{icon}:]({href} 'Default value')",
        text = text
    )

# Create badge for experimental flag
def _badge_for_experimental(page: Page, files: Files):
    icon = "material-flask-outline"
    href = _resolve_path("sw/changelog/conventions.md#experimental", page, files)
    return _badge(
        icon = f"[:{icon}:]({href} 'Experimental')"
    )