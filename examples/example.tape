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
Type "# Virtfs is an Elixir Mock Filesystem, that keeps your SSD longer alive :)" Sleep 2 Enter
Type "# Let's see it in action!" Sleep 2 Enter Sleep 0.5

Hide
Type "iex -S mix" Enter
Type "clear" Enter

Show
# Recording

Type '# Start a virtual FS system and play with it' Sleep 1 Enter Sleep 0.5
Type@.2 '{:ok, fs} = Virtfs.start_link()' Sleep 1 Enter Sleep 0.5

Type '# Writing to a file' Sleep 1 Enter Sleep 0.5
Type@.2 ':ok = Virtfs.write!(fs, "some/file.txt", "content")' Sleep 1 Enter Sleep 0.5
Type@.2 ':ok = Virtfs.write!(fs, "some/file2.txt", "content")' Sleep 1 Enter Sleep 0.5

Type '# Listing a folder' Sleep 1 Enter Sleep 0.5
Type@.2 '["/some/file.txt", "/some/file2.txt"] = Virtfs.ls!(fs, "some")' Sleep 1 Enter Sleep 0.5

Type '# Reading a file' Sleep 1 Enter Sleep 0.5
Type@.2 '"content" = Virtfs.read!(fs, "/some/file2.txt")' Sleep 1 Enter Sleep 0.5

Type '# Moving around in the file system with `cd`' Sleep 1 Enter Sleep 0.5
Type@.2 ':ok = Virtfs.cd(fs, "some")' Sleep 1 Enter Sleep 0.5
Type@.2 '"content" = Virtfs.read!(fs, "file2.txt")' Sleep 1 Enter Sleep 0.5

Type '# Tree to see all subfolders' Sleep 1 Enter Sleep 0.5
Type@.2 '["/some", "/some/file.txt", "/some/file2.txt"] = Virtfs.tree!(fs, "/")' Sleep 1 Enter Sleep 0.5

Type '# Dump in-memory FS into a folder' Sleep 1 Enter Sleep 0.5
Type@.2 'File.rm_rf("/tmp/virtfs_test")' Sleep 1 Enter Sleep 0.5
Type@.2 'Virtfs.dump(fs, "/tmp/virtfs_test")' Sleep 1 Enter Sleep 0.5
Type@.2 '["file2.txt", "file.txt"] = File.ls!("/tmp/virtfs_test/some")' Sleep 1 Enter Sleep 0.5


Type '# Load files from a folder' Sleep 1 Enter Sleep 0.5
Type@.2 '{:ok, fs} = Virtfs.start_link()' Sleep 1 Enter Sleep 0.5
Type@.2 'Virtfs.load(fs, "/tmp/virtfs_test")' Sleep 1 Enter Sleep 0.5
Type@.2 '["/some", "/some/file.txt", "/some/file2.txt"] = Virtfs.tree!(fs, "/")' Sleep 1 Enter Sleep 0.5

Type '# Enjoy using it! 💜' Sleep 1 Enter Sleep 0.5
