# mibap - macOS Inkscape Build And Package
The Inkscape devs need help with compiling and packaging on macOS ("from source to dmg"). I want to help, so let's see how far we come. I'm saying "we" because this is not a singular person's effort, it's a joint effort. I want to take a look at and (hopefully) build upon what others have come up with. Ideally we can take this past the finish line, but if not, someone else will have the chance to pick up the torch.

This is an activity log and/or notepad of sorts. Mind that this here is all work in progress, far from being polished or in a presentable state. It'll stay "dirty" until it actually does what it's supposed to do.  
Final goal is that there will be scripts and stuff here that we can PR to Inkscape.

# 04.03.2019
- Began work on script to create application bundle.
  - First step was creating a recursive function to parse all dynamically linked libraries from a given starting point (the inkscape binary).

__Next__: continue work on script

# 27.02.2019
- Cloned the Inkscape master branch (1.0 alpha is only a tag, not a branch) to try my luck again.
  - I'm happily surprised that compilation was fine :-). Quite a few warnings, but that's to be expected from a huge piece of software. 
  - The resulting build appears to be working (no real testing done).
- Master branch was at commit a456169068e7a1ca8715860715fbe912d6cf7fa5.
  - Since this is now known to work, I'll be using this exact commit as a base. Once I get the whole build chain (source to dmg) up and running, I'll re-open this to always us the current master code.

__Next__: create application bundle

# 23.02.2019
Starting point for everything is a clean macOS 10.13.6 installation. "Clean" as in "freshly installed + XCode". 
- Based on ipatch's notes:
  - Created script to prepare build environment. (WIP, unpolished!)
  - Created script to build Inkscape. (WIP, unpolished!)
- I encountered warnings during compilation (warnings are treated as errors). Quick&dirty fix is to disable those warnings using the corresponding compiler flags. At least one warning is suspicious (comparison between string literal) and warrants further investigation sometime later, so I'm leaving this as TODO for now.
  ```
  /Volumes/WORK/inkscape-INKSCAPE_1_0_ALPHA/src/extension/internal/gdkpixbuf-input.cpp:56:56: warning: result of comparison against a string literal is unspecified (use strncmp instead) [-Wstring-compare]
        forcexdpi = (mod->get_param_optiongroup("dpi") == "from_default");
                                                       ^  ~~~~~~~~~~~~~~
  ```
- Compilation fails with
  ```
  [ 31%] Building CXX object src/CMakeFiles/inkscape_base.dir/extension/internal/wmf-inout.cpp.o
  /Volumes/WORK/inkscape-INKSCAPE_1_0_ALPHA/src/extension/internal/cairo-renderer.cpp:340:18: error: no member named 'showGlyphs' in 'Inkscape::Text::Layout'
    text->layout.showGlyphs(ctx);
    ~~~~~~~~~~~~ ^
  /Volumes/WORK/inkscape-INKSCAPE_1_0_ALPHA/src/extension/internal/cairo-renderer.cpp:345:22: error: no member named 'showGlyphs' in 'Inkscape::Text::Layout'
    flowtext->layout.showGlyphs(ctx);
    ~~~~~~~~~~~~~~~~ ^
  2 errors generated.
  make[2]: *** [src/CMakeFiles/inkscape_base.dir/extension/internal/cairo-renderer.cpp.o] Error 1
  make[2]: *** Waiting for unfinished jobs....
  make[1]: *** [src/CMakeFiles/inkscape_base.dir/all] Error 2
  make: *** [all] Error 2
  ```
  Preliminary analysis suggests that a missing dependency leads to `Layout::showGlyphs()` being omitted in `src/libnrtype/Layout-TNG.h`:
  ```
  #ifdef HAVE_CAIRO_PDF    
    /** Renders all the glyphs to the given Cairo rendering context.
     \param ctx   The Cairo rendering context to be used
     */
     void showGlyphs(CairoRenderContext *ctx) const;
  #endif
  ```
__Next__: investigate `HAVE_CAIRO_PDF` (probably recompilation of Cairo with additional feature flags required?), compile current Git master. 

# 22.02.2019
- Homebrew formula is https://github.com/caskformula/homebrew-caskformula
  - a bit out of date
  - commentend on [Issue 75](https://github.com/caskformula/homebrew-caskformula/issues/75) asking for ipatch's current working build: [ipatch's work](https://github.com/ipatch/homebrew-us-05/blob/master/inkscape/inkscape-building-for-macOS.md)
- MacPorts portfile is https://github.com/macports/macports-ports/blob/master/graphics/inkscape/Portfile
  - based on last commit, seems pretty current

__Next__: build using ipatch's notes