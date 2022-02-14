#!/usr/bin/bash
radarr_label="Movies"

echo "radarr_moviefile_sourcepath: $radarr_moviefile_sourcepath" >> /config/logs/symlink.log
echo "radarr_moviefile_path: $radarr_moviefile_path" >> /config/logs/symlink.log

# Make sure we're working on torrents.
if ! [[ "${radarr_moviefile_sourcepath}" =~ radarr ]]; then
  echo "[Torrent Symlink] Path ${radarr_moviefile_sourcepath} does not contain \"torrent\", exiting." >> /config/logs/symlink.log
  exit
fi

# If the source file doesn't exist, error out.
if ! [[ -f "${radarr_moviefile_sourcepath}" ]]; then
  echo "[Torrent Symlink] File ${radarr_moviefile_sourcepath} does not exist, exiting." >> /config/logs/symlink.log
  exit 1
fi

# If it isn't a single file, it might be a packed release which should be skipped.
base_dir=$( basename "${radarr_moviefile_sourcefolder}" )
if [[ "${base_dir}" != "${radarr_label}" ]] && find "${radarr_moviefile_sourcefolder}" -iregex '.*\.r[0-9a][0-9r]$' | grep -Eq '.*'; then
  echo "[Torrent Symlink] Found rar or r00 files, skipping symlink creation." >> /config/logs/symlink.log
  exit
fi

# Make sure the copy is done by comparing source and destination file sizes.
orig_file_size=$(stat -c%s "${radarr_moviefile_sourcepath}")
dest_file_size=$(stat -c%s "${radarr_moviefile_path}")

# Make the actual symlink.
if [[ ${dest_file_size} == "${orig_file_size}" ]]; then
  echo -n "[Torrent Symlink] Switching ${radarr_moviefile_sourcepath} to symlink pointed at ${radarr_moviefile_path}... " >> /config/logs/symlink.log
  if rm "${radarr_moviefile_sourcepath}" && ln -s "${radarr_moviefile_path}" "${radarr_moviefile_sourcepath}"; then
    echo "done."
  else
    echo "failed."
    exit 1
  fi
else
  echo "[Torrent Symlink] Size of ${radarr_moviefile_sourcepath} and ${radarr_moviefile_path} differ, skipping." >> /config/logs/symlink.log
fi