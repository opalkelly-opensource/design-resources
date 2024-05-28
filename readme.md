# Opal Kelly Design Resources

Components, examples and tools provided to facilitate usage of Opal Kelly products.

## [ExampleProjects](/ExampleProjects)
Full featured example projects

## [HDLComponents](/HDLComponents)
Component usage examples

## [BoardTools](/BoardTools)
Tools for various Opal Kelly products

---

**Notice Regarding Path Length Limitation in Windows with Vivado Builds**

This repository contains files with long paths, which may cause issues when building with Vivado on Windows. Vivado may generate file paths that, when combined with our repository paths, exceed the 260-character limit on Windows systems, leading to errors during the build process.

For solutions and workarounds, refer to [AMD's AR52787](https://www.xilinx.com/support/answers/52787.html), which provides detailed guidance based on your preferences.

If you encounter path length errors, move the specific project you're working on to a location closer to the root of your C: drive, such as `C:/project/`. This will shorten paths during Vivado builds and will help avoid errors.
