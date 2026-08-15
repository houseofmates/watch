#!/bin/bash
# launch watch with www-data group for nextcloud media access
exec sg www-data -c "cd /home/house/projects/watch && exec ./releases/watch \"\$@\""