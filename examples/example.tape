# VHS tape. For examples look here: https://github.com/charmbracelet/vhs/tree/main/examples

Output examples/example.mp4

Set Shell "fish"
Set FontSize 26
# Set FontFamily "Monaco"
Set FontFamily "Hack Nerd Font Mono"
Set Width 1600
Set Height 800
Set Padding 20
Set TypingSpeed 80ms
Set Theme "Builtin Solarized Light"

# Setup

Show
Type "# Virtfs is an Elixir In-Memory file system, that keeps your SSD longer alive :)" Sleep 2 Enter Sleep 0.5
Type "# Let's see it in action!" Sleep 2 Enter Sleep 0.5

Hide
Type "iex -S mix" Enter
Type 'File.rm_rf("/tmp/virtfs_test")' Enter
Type "clear" Enter

Show
# Recording
## PASTE SCRIPT GENERATED BY RUNNING `make gen_tape`

Type@.3 '# Start a virtual FS system and play with it' Sleep 0.5 Enter Sleep 0.3
Type@.2 '{:ok, fs} = Virtfs.start_link()' Sleep 0.5 Enter Sleep 0.3

Type@.3 '# Writing to a file' Sleep 0.5 Enter Sleep 0.3
Type@.2 ':ok = Virtfs.write!(fs, "some/file.txt", "content")' Sleep 0.5 Enter Sleep 0.3
Type@.2 ':ok = Virtfs.write!(fs, "some/file2.txt", "content")' Sleep 0.5 Enter Sleep 0.3

Type@.3 '# Listing a folder' Sleep 0.5 Enter Sleep 0.3
Type@.2 '["/some/file.txt", "/some/file2.txt"] = Virtfs.ls!(fs, "some")' Sleep 0.5 Enter Sleep 0.3

Type@.3 '# Reading a file' Sleep 0.5 Enter Sleep 0.3
Type@.2 '"content" = Virtfs.read!(fs, "/some/file2.txt")' Sleep 0.5 Enter Sleep 0.3

Type@.3 '# Moving around in the file system with `cd`' Sleep 0.5 Enter Sleep 0.3
Type@.2 ':ok = Virtfs.cd(fs, "some")' Sleep 0.5 Enter Sleep 0.3
Type@.2 '"content" = Virtfs.read!(fs, "file2.txt")' Sleep 0.5 Enter Sleep 0.3

Type@.3 '# Tree to see all subfolders' Sleep 0.5 Enter Sleep 0.3
Type@.2 '["/some", "/some/file.txt", "/some/file2.txt"] = Virtfs.tree!(fs, "/")' Sleep 0.5 Enter Sleep 0.3

Type@.3 '# Dump in-memory FS into a folder' Sleep 0.5 Enter Sleep 0.3
Type@.3 '# Make sure, our destination folder is empty' Sleep 0.5 Enter Sleep 0.3
Type@.2 'File.rm_rf("/tmp/virtfs_test")' Sleep 0.5 Enter Sleep 0.3
Type@.2 'Virtfs.dump(fs, "/tmp/virtfs_test")' Sleep 0.5 Enter Sleep 0.3
Type@.2 '["file2.txt", "file.txt"] = File.ls!("/tmp/virtfs_test/some")' Sleep 0.5 Enter Sleep 0.3


Type@.3 '# Load files from a folder' Sleep 0.5 Enter Sleep 0.3
Type@.2 '{:ok, fs} = Virtfs.start_link()' Sleep 0.5 Enter Sleep 0.3
Type@.2 'Virtfs.load(fs, "/tmp/virtfs_test")' Sleep 0.5 Enter Sleep 0.3
Type@.2 '["/some", "/some/file.txt", "/some/file2.txt"] = Virtfs.tree!(fs, "/")' Sleep 0.5 Enter Sleep 0.3

Type@.3 '# Enjoy using it! 💜' Sleep 0.5 Enter Sleep 0.3