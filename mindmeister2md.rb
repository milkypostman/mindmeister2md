# Tagging

## tagging vs folders

* folders
  * static
  * unintuitive
  * hierarchical groupings
  * has to be date-based, project-based, media-type based, etc.
* tagging
  * group things every way that makes sense
  * search is more flexible
  * additional possibilities
    * Hazel actions
    * super tags
      * target tags
    * Scripting

## The combo system

* I file tagged files in folders
  * limited-level folder hierarchy
    * Work
      * client
      * client
    * Code
      * project
      * project
* tags can exist within folders just fine
* Folders provide visual and mental organization
* One Big Pile is a misnomer
  * Nobody does that, do they?
  * Smaller &quot;Piles&quot; are for general topics
    * Similar to Evernote Notebooks
    * Inspirational references go in a pile
    * TUAW post drafts go in a pile
    * Brettterpstra.com post drafts go in a pile
    * Piles are searched and filtered with text content and tags

## Intelligent tagging

* minimal number of tags
  * tags get unmanageable in a large group
  * use &quot;real&quot; words
    * Project or topic
    * the first word that comes to mind
      * probably what you'll use to find it again in the future
    * a logical secondary topic or project name
  * think like folders
    * but multiple instead of hierarchical
  * skip &quot;flagged&quot; tags
    * &quot;interesting&quot;, &quot;due&quot;, &quot;urgent&quot;, etc.
    * Too much review
      * Un-reviewed &quot;flags&quot; become irrelevant rapidly
    * ineffective to prioritize in tagging's non-linear fashion.
    * exception for &quot;inspiration&quot;
      * subtags
        * Webdesign
        * Productivity
        * Color
  * skip existing metadata
    * created/modified date
    * Spotlight notes
    * keywords existing within searchable content
    * Filename
    * Filetype
* Reuse tags consistently
  * &quot;blogpost&quot; and &quot;blogposts&quot; aren't grouped effectively
  * Reference similar files to replicate tags
  * doesn't take any longer than filing in folders would
  * Most apps provide auto-completion and recent/common tags
  * Make a cheat sheet
    * Keep a Notational Velocity note with tags you might forget
    * Paper is an option, of course
    * Especially track special conventions
* special conventions
  * Tag prefixes
    * source:, project:, etc.
    * special character prefixes
      * helpful for creating &quot;supertags&quot; used in creating extra functionality
  * benefits
    * make some part of the tag memorable in case you forget the rest
    * can group tags anywhere
      * type the first character and get all the subgroups
    * sort to the top in most tag lists

## interoperability

* Tagging system is only as good as the search system
* Spotlight and OpenMeta combine all supported apps in one search
  * Apps can use proprietary tagging systems, as long as they write OpenMeta tags to disk for Spotlight
    * Thanks to Tags and the OpenMeta project, it's possible to shell and AppleScript the process for many unsupported apps
* support from devs
  * Spotlight/Finder
    * a &quot;tag:&quot; prefix searches tags
    * can be combined with other Spotlight queries
    * Save searches as Finder Smart Folders
  * Tags
    * Hotkey HUD for adding OpenMeta tags
    * The fastest way to tag *anything*
      * Mail.app emails
      * iCal events
      * iPhoto photos
      * Finder files
      * Current document in most apps
      * Web locations
    * Tag/Spotlight search in menubar with drilldown
  * Notational Velocity
    * Latest version copies note tags to OpenMeta tags on filesystem files
  * Together
    * Reads and writes OpenMeta tags from disk
  * DEVONthink
    * Includes tags as OpenMeta on exported files
  * EagleFiler
    * Reads and writes OpenMeta tags to disk
  * Leap
    * A Finder replacement built on OpenMeta tagging
  * Yep
    * PDF filing, essentially a lightweight Leap
  * Deep
    * Search images by color, size and tag, add tags quickly
  * Default Folder X
    * Allows tagging when saving files
  * HoudahSpot
    * Enhanced Spotlight search, including tags and keywords
    * Also includes slide-out drawer with drag and drop tagging
  * Evernote
    * Not OpenMeta, but add a &quot;keyword&quot; predicate to Spotlight search and they'll mix

## Additional notes

* OpenMeta may not be future-proof
  * legitimate concern
  * data is backed up
  * Snow Leopard already broke it once, but it was immediately worked around
* Mac App Store rejection because of OpenMeta
  * Universal tag backup system breaks the rules
  * Each app has to be sandboxed
  * Still workable, but inconvenient and redundant
