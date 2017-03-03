from __future__ import unicode_literals

import biplist
import os.path

# Default contents

volume_name = 'Vagrant'
format = defines.get('format', 'UDZO')
size = defines.get('size', '102400k')
files = defines.get('srcfolder')

# Set the background

background = defines.get('backgroundimg', 'builtin-arrow')

# Hide things we don't want to see

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

# Set size and view style

window_rect = ((100, 100), (605, 540))
default_view = 'icon-view'

# Arrange contents

arrange_by = None
icon_size = 72
icon_locations = {
    'Vagrant.pkg': (420, 60),
    'uninstall.tool': (420, 220)
}
