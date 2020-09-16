# Functional Dependencies...
###Example:
Given x, function f can be used to determine y
    f(x) -> y
y2 and y2 can be derived from function f when given x
    f(x) -> y1, y2
z can be derived from function f when given x and y
    f(x, y) -> z
any RHS element can be used in LHS arguments.

## Process to scrape data for ingestion to Postgres (Web-ready DB)
In a nutshell I’ve written the code to append the necessary keys and generate SQL code for each sqlite DB. I’ve also written XSLT stylesheets that convert any *.proj into SQL. Both of these are loaded into Postgres, but order of loading is important. It wasn’t until I did this analysis that I realised had to happen in this specific order:
1.	Glaciator Projects
2.	project_info.sqlite
3.	Frost Projects
4.	Frappeator Projects
5.	Frappe Projects
6.	Other *.sqlite

### Step 1
Beginning with our database we can gain access to read-to-import jobs keyed with a UUID.

    (indb link) -> job, jobstate
    (job, jobstate) -> uuid

### Step 2
Given root directory and where to look we can derive a collection GlaciatorProjects
    (datastorage, '/glaciator_out/glaciator_project_file', uuid) -> GlaciatorProject

### Step 3
We can examine frappeator_settings and exit here if not true
    (GlaciatorProject) -> frappeator_settings -> run_frappeator == true

### Step 4

    (GlaciatorProject) -> frost_auto_multi_project_regular
    (GlaciatorProject) -> frost_auto_multi_project_regular -> output_dir_path
    (GlaciatorProject) -> frost_auto_multi_project_regular -> subproject_name_mask
    (GlaciatorProject) -> frost_auto_multi_project_regular -> output_dir_path -> glaciator_project_name

    (GlaciatorProject) -> glaciator_project_name
    (GlaciatorProject) -> frost_auto_multi_project_regular -> multi_project_name

    (output_dir_path, glaciator_project_name, multi_project_name, subproject_name_mask) -> SUB_PROJECT

    (SUB_PROJECT) -> fire_impacts.sqlite
    (SUB_PROJECT) -> project_info.sqlite
    (SUB_PROJECT) -> machinery_settings
    (SUB_PROJECT) -> frost.proj

    (fire_impacts.sqlite) -> nothing directly useful (yet)
    (machinery_settings) -> nothing directly useful (yet)

    (frost.proj) -> frost_regsim_project -> project_name
    (frost.proj) -> frost_regsim_project -> output_root_dir

### Step 5
Any and all proj files can be imported to postgres at any time.

    (*.proj + .xsl) -> XSLTransform() -> SQL
    (*.sqlite) -> SQLiteAdaptor() -> SQL
    (SQLiteAdaptor(), regime, replicate, uuid) -> Modified_SQL

### Step 6

Interrogating project_info reveals the relevant and useful info...
    (project_info.sqlite)-> Project
    (project_info.sqlite)-> Project -> descr
We need to write a function here to determine the length of the multi-projects because this info is not held anywhere else until this point.
    (project_info.sqlite)-> Project -> parse(descr) -> length_of_multiproject
    (project_info.sqlite)-> Project -> simgrid_id

    (project_info.sqlite)-> Scenario
    (project_info.sqlite)-> Scenario -> scenario_id
    (project_info.sqlite)-> Scenario -> type

    (project_info.sqlite)-> SpaceGrid
    (project_info.sqlite)-> SpaceGrid -> left
    (project_info.sqlite)-> SpaceGrid -> right
    (project_info.sqlite)-> SpaceGrid -> top
    (project_info.sqlite)-> SpaceGrid -> bottom
    (project_info.sqlite)-> SpaceGrid -> cell_size

### Step 7
We can read frappeator_output_root_dir_path but this is a folder only...
    (GlaciatorProject) -> frappeator_settings -> frappeator_output_root_dir_path
Please note:  (this is top_level_only for frappeator!)

    (GlaciatorProject) -> frappeator_settings -> is_frost_multi_proj
*is_frost_multi_proj* allows us to expect sub-projects, so from...
    (GlaciatorProject) -> frost_auto_multi_project_regular -> subproject_name_mask

### Step 8
Pulling together what we know allows us to find_frappeators()
    (frappeator_output_root_dir_path,
    multi_project_name,
    length_of_multiproject,
    subproject_name_mask,
    datastorage+'/frappeator_out') -> FrappeatorProject

    (FrappeatorProject) -> regime

    (FrappeatorProject) -> frappeator_output_root_dir_path
    (FrappeatorProject) -> frappe_multi_project
    (FrappeatorProject) -> frappe_multi_project -> frost_output_results_dir_rel_path

    (frappeator_output_root_dir_path,
    frost_output_results_dir_rel_path,
    multi_project_name,
    length_of_multiproject,
    subproject_name_mask) -> FrappeProject

    -> {OR what I have been calling 'replicate’ eg ‘rep-1-1'}


### Step 9
Given the const 'post_processing_output'

    (FrappeProject, 'post_processing_output') -> gma_post_proc_results.sqlite
    (FrappeProject, 'post_processing_output') -> hydro_machine_results.sqlite
    (FrappeProject, 'post_processing_output') -> pb_statistics.sqlite
    (FrappeProject, 'post_processing_output') -> phibc_post_proc_results.sqlite
    (FrappeProject, 'post_processing_output/gma_output') -> *.shp

And when we import those files, appending replicate, regime and UUID:
    (path to *.shp, replicate, regime and UUID) -> link_for_db_storage_of_shp_location
    (gma_post_proc_results.sqlite, replicate, regime and UUID) -> SQL
    (hydro_machine_results.sqlite, replicate, regime and UUID) -> SQL
    (pb_statistics.sqlite, replicate, regime and UUID) -> SQL
    (phibc_post_proc_results.sqlite, replicate, regime and UUID) -> SQL

### Step 10

Ready to insert
    (SQL) -> outdb
