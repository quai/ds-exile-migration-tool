# ds-exile-migration-tool

Dayz-Survivors migration tools for Exile Mod.

Work in progress

## Goal

Build a tool that could make it possible to remove or replace items belonging to third-party mods on a Arma 3 server running the Exile Mod.

### Method

For the scope of this tool, it will operate against a database dump of the existing server, and result in a SQL-file that can be imported in to the new server.

The tool should be able to parse out and build a map of the different items provided by the mods. The system should be able to detect the currently used mods from the database, and let the user choice a list of mods it wants to have active on the new installation. The system should then show a list of the items that needs to be removed or replaced.

### Limitations

Items that included a location like players, constructions, containers and vehicle might be problematic if the mod that are added or removed has made changes to the map. When removing mods that contains backpacks, vests and uniforms replacements with the same of larger capacity have to be defined.
