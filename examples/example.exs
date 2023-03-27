# Start a virtual FS system and play with it
{:ok, fs} = Virtfs.start_link()

# Writing to a file
:ok = Virtfs.write!(fs, "some/file.txt", "content")
:ok = Virtfs.write!(fs, "some/file2.txt", "content")

# Listing a folder
["/some/file.txt", "/some/file2.txt"] = Virtfs.ls!(fs, "some")

# Reading a file
"content" = Virtfs.read!(fs, "/some/file2.txt")

# Moving around in the file system with `cd`
:ok = Virtfs.cd(fs, "some")
"content" = Virtfs.read!(fs, "file2.txt")

# Tree to see all subfolders
["/some", "/some/file.txt", "/some/file2.txt"] = Virtfs.tree!(fs, "/")

# Dump in-memory FS into a folder
File.rm_rf("/tmp/virtfs_test")
Virtfs.dump(fs, "/tmp/virtfs_test")
["file2.txt", "file.txt"] = File.ls!("/tmp/virtfs_test/some")


# Load files from a folder
{:ok, fs} = Virtfs.start_link()
Virtfs.load(fs, "/tmp/virtfs_test")
["/some", "/some/file.txt", "/some/file2.txt"] = Virtfs.tree!(fs, "/")

# Enjoy using it! 💜
