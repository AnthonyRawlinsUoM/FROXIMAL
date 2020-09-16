create table job
(
    id                   bigint generated always as identity
        constraint "Job_pkey"
            primary key,
    name                 text      not null,
    descr                text,
    uuid                 text      not null,
    submission_time      timestamp not null,
    submitter_name       text      not null,
    submitter_email      text      not null,
    weather_machine_kind smallint  not null,
    fuel_machine_kind    smallint  not null,
    fire_history_kind    smallint  not null,
    planburn_target_perc real      not null,
    harvesting_on        boolean   not null,
    regsim_duration      smallint  not null,
    num_replicates       smallint  not null
);

alter table job
    owner to postgres;

grant insert, select, update, delete, truncate, references, trigger on job to public;

create unique index job_uuid_uindex
    on job (uuid);

create table jobstate
(
    id                          bigint generated always as identity
        constraint "JobState_pkey"
            primary key,
    status                      smallint  not null,
    machine_name                text      not null,
    simulation_start_time       timestamp not null,
    simulation_warnings         text,
    simulation_results_dir_path text,
    post_proc_start_time        timestamp,
    post_proc_warnings          text,
    post_proc_results_dir_path  text,
    job_failure_time            timestamp,
    job_completion_time         timestamp,
    job_failure_error_message   text,
    published                   boolean default false
);

alter table jobstate
    owner to postgres;

grant insert, select, update, delete, truncate, references, trigger on jobstate to public;

create table jobtojobstate
(
    job_id       bigint not null
        constraint "JobToJobState_job_id_fkey"
            references job,
    job_state_id bigint not null
        constraint "JobToJobState_job_state_id_fkey"
            references jobstate
);

alter table jobtojobstate
    owner to postgres;

grant insert, select, update, delete, truncate, references, trigger on jobtojobstate to public;

create table "SchemaVersion"
(
    version_no smallint not null
);

alter table "SchemaVersion"
    owner to postgres;

create table succession_settings
(
    succession_settings_id bigserial not null
        constraint succession_settings_pkey
            primary key,
    landis_data_available  boolean,
    harvest_data_available boolean,
    run_biomass            boolean,
    run_harvest            boolean,
    run_hcv                boolean,
    run_carbon_landis      boolean
);

alter table succession_settings
    owner to postgres;

create table gma_settings
(
    gma_settings_id            bigserial not null
        constraint gma_settings_pkey
            primary key,
    run_gma                    boolean   not null,
    run_age_distr_gma_detached boolean   not null
);

alter table gma_settings
    owner to postgres;

create table fuel_machine_type
(
    fuel_machine_type_id   serial not null
        constraint fuel_machine_type_pkey
            primary key,
    fuel_machine_type_name text
);

alter table fuel_machine_type
    owner to postgres;

create table rusle_settings
(
    rusle_settings_id bigserial not null
        constraint rusle_settings_pkey
            primary key,
    c_peak            numeric,
    c_harvpeak        numeric,
    xic_fire          numeric,
    xik_fire          numeric,
    xic_harv          numeric,
    xik_harv          numeric,
    k_fire_multiplier numeric,
    k_harv_multiplier numeric,
    r_climate         numeric,
    weather_type      text
);

alter table rusle_settings
    owner to postgres;

create table hydro_settings
(
    hydro_settings_id bigserial not null
        constraint hydro_settings_pkey
            primary key,
    rusle_settings_id integer
        constraint hydro_settings_rusle_settings_rusle_settings_id_fk
            references rusle_settings,
    run_hydro         boolean
);

alter table hydro_settings
    owner to postgres;

create table frappe_projects
(
    frappe_project_id              bigserial not null
        constraint frappe_projects_pkey
            primary key,
    version                        integer,
    project_name                   text,
    project_descr                  text,
    frost_machinery_data_root_dir  text,
    frost_output_results_root_dir  text,
    frappe_output_results_root_dir text,
    fuel_machine_type_id           integer
        constraint frappe_projects_fuel_machine_type_fuel_machine_type_id_fk
            references fuel_machine_type,
    run_biodiversity               boolean,
    run_genasset                   boolean,
    run_infrustruct                boolean,
    run_people_house_loss          boolean,
    run_viewshed                   boolean,
    run_carbon                     boolean,
    run_pb_stat                    boolean,
    hydro_settings_id              bigint
        constraint frappe_projects_hydro_settings_hydro_settings_id_fk
            references hydro_settings,
    gma_settings_id                bigint
        constraint frappe_projects_gma_settings_gma_settings_id_fk
            references gma_settings,
    succession_settings_id         bigint
        constraint frappe_projects_succession_settings_succession_settings_id_fk
            references succession_settings,
    uuid                           text
        constraint frappe_projects_job_uuid_fk
            references job (uuid),
    replicate                      bigint,
    regime_id                      bigint
);

alter table frappe_projects
    owner to postgres;

create table glaciator_projects
(
    glaciator_project_id          bigserial not null
        constraint glaciator_projects_pkey
            primary key,
    name                          text      not null,
    uuid                          text      not null
        constraint glaciator_projects_job_uuid_fk
            references job (uuid),
    version                       real      not null,
    glaciator_project_description text
);

alter table glaciator_projects
    owner to postgres;

create table frappeator_settings
(
    frappeator_settings_id          bigserial not null
        constraint frappeator_settings_pkey
            primary key,
    frappeator_output_root_dir_path text      not null,
    frappeator_exe_path             text      not null,
    uuid                            text      not null
        constraint frappeator_settings_job_uuid_fk
            references job (uuid),
    run_frappeator                  boolean   not null,
    is_frost_multi_proj             boolean   not null,
    concurrent_threads              integer   not null,
    frappe_exe_path                 text
);

alter table frappeator_settings
    owner to postgres;

create table frappe_project_template_files
(
    frappe_project_template_files_id bigserial not null
        constraint frappe_project_template_files_pkey
            primary key,
    id                               text      not null,
    path                             text      not null,
    uuid                             text      not null
        constraint frappe_project_template_files_job_uuid_fk
            references job (uuid)
);

alter table frappe_project_template_files
    owner to postgres;

create table frost_auto_multi_project_regular
(
    frost_auto_multi_project_regular_id bigserial not null
        constraint frost_auto_multi_project_regular_pkey
            primary key,
    multi_project_name                  text      not null,
    machines_settings_file_id           integer   not null,
    start_year_of_first_regsim_fireyear integer   not null,
    regsim_duration_years               integer   not null,
    years_between_regsims               integer   not null,
    subproject_name_mask                text      not null,
    regsim_index_start                  integer   not null,
    regsim_index_end                    integer   not null,
    frappe_project_template_file_id     bigint    not null,
    uuid                                text      not null
        constraint frost_auto_multi_project_regular_job_uuid_fk
            references job (uuid),
    output_dir_path                     text      not null
);

alter table frost_auto_multi_project_regular
    owner to postgres;

create table multi_startup_fuel_info
(
    multi_startup_fuel_info_id    bigserial not null
        constraint multi_startup_fuel_info_pkey
            primary key,
    fire_history_zipgrid_filename text,
    aligned_fire_history          text,
    uuid                          text      not null
        constraint multi_startup_fuel_info_job_uuid_fk
            references job (uuid)
);

alter table multi_startup_fuel_info
    owner to postgres;

create table frappeator_projects
(
    frappeator_project_id                  bigserial not null,
    name                                   text      not null,
    version                                numeric   not null,
    project_descr                          text      not null,
    glaciator_output_results_root_dir_path text      not null,
    frappeator_output_root_dir_path        text      not null,
    frappe_exe_path                        text      not null,
    is_frost_multi_proj                    boolean   not null,
    concurrent_threads                     integer   not null,
    uuid                                   text      not null
        constraint frappeator_projects_job_uuid_fk
            references job (uuid),
    constraint frappeator_projects_pkey
        primary key (frappeator_project_id, uuid)
);

alter table frappeator_projects
    owner to postgres;

create table frappe_multi_projects
(
    frappe_multi_project_id           bigserial not null
        constraint frappe_multi_projects_pkey
            primary key,
    frost_output_results_dir_rel_path text      not null,
    frappe_project_file_id            bigint    not null,
    uuid                              text      not null
        constraint frappe_multi_projects_job_uuid_fk
            references job (uuid)
);

alter table frappe_multi_projects
    owner to postgres;

create table frost_projects
(
    frost_project_id                  bigserial not null
        constraint frost_projects_pkey
            primary key,
    version                           integer,
    name                              text      not null,
    type                              integer   not null,
    descr                             text,
    start_year_of_first_fireyear      integer,
    start_year_of_last_fireyear       integer,
    last_burnt_info_grid_repo_file_id integer,
    fuel_load_grid_repo_file_id       integer,
    simgrid_id                        integer   not null,
    machinery_input_root_dir_path     text      not null,
    output_root_dir_path              text      not null,
    uuid                              text      not null
        constraint frost_projects_uuid_fkey
            references job (uuid)
);

alter table frost_projects
    owner to postgres;

create table frost_scenarios
(
    frost_scenario_id     bigserial not null
        constraint frost_scenarios_pkey
            primary key,
    type                  integer,
    weather_id            integer,
    suppression_id        integer,
    fuel                  text,
    fire_history          text,
    disruption            text,
    supplementary_history text,
    sim_period_start      timestamp,
    sim_period_end        timestamp,
    grid_resolution       real,
    uuid                  text
        constraint frost_scenarios_uuid_fkey
            references job (uuid)
);

alter table frost_scenarios
    owner to postgres;

create table spacegrid
(
    spacegrid_id bigserial not null
        constraint spacegrid_pkey
            primary key,
    type         integer   not null,
    _left        real      not null,
    bottom       real      not null,
    width        real      not null,
    height       real      not null,
    cell_size    real      not null,
    uuid         text
        constraint spacegrid_uuid_fkey
            references job (uuid),
    regime_id    bigint,
    replicate    text,
    id           bigint
);

alter table spacegrid
    owner to postgres;

create table startup_fuel_info
(
    startup_fuel_info_id          bigserial not null
        constraint startup_fuel_info_pkey
            primary key,
    fire_history_zipgrid_filename text,
    current_in_year               integer,
    uses_fire_history             boolean   not null,
    aligned_fire_history          boolean,
    replicate                     text      not null,
    uuid                          text      not null
        constraint startup_fuel_info_uuid_fkey
            references job (uuid)
);

alter table startup_fuel_info
    owner to postgres;

create table frost_regsim_projects
(
    frost_regsim_project_id      bigserial not null
        constraint frost_regsim_projects_pkey
            primary key,
    project_name                 text      not null,
    version                      numeric,
    project_descr                text,
    machines_in_files_root_dir   text      not null,
    base_dataset_id              integer   not null,
    output_root_dir              text      not null,
    start_year_of_first_fireyear integer   not null,
    start_year_of_last_fireyear  integer   not null,
    startup_fuel_info_id         integer
        constraint frost_regsim_projects_startup_fuel_info_id_fkey
            references startup_fuel_info,
    uuid                         text      not null
        constraint frost_regsim_projects_uuid_fkey
            references job (uuid),
    replicate                    text
);

alter table frost_regsim_projects
    owner to postgres;

create table project
(
    name                              text    not null,
    type                              integer not null,
    descr                             text,
    start_year_of_first_fireyear      integer,
    start_year_of_last_fireyear       integer,
    last_burnt_info_grid_repo_file_id integer,
    fuel_load_grid_repo_file_id       integer,
    simgrid_id                        integer not null,
    machinery_input_root_dir_path     text    not null,
    output_root_dir_path              text    not null,
    regime_id                         integer not null
        constraint project_regime_id_fkey
            references frost_regsim_projects,
    replicate                         text    not null,
    uuid                              text    not null
        constraint project_uuid_fkey
            references job (uuid)
);

alter table project
    owner to postgres;

create table scenario
(
    id                    integer not null,
    type                  integer not null,
    weather_id            integer,
    suppression_id        integer,
    fuel                  text,
    fire_history          text,
    disruption            text,
    supplementary_history text,
    sim_period_start      timestamp,
    sim_period_end        timestamp,
    grid_resolution       real,
    regime_id             integer not null
        constraint scenario_regime_id_fkey
            references frost_regsim_projects,
    replicate             text    not null,
    uuid                  text    not null
        constraint scenario_uuid_fkey
            references job (uuid),
    constraint scenario_pkey
        primary key (id, replicate, regime_id, uuid, type)
);

alter table scenario
    owner to postgres;

create table version
(
    version_no integer not null,
    regime_id  integer not null
        constraint version_regime_id_fkey
            references frost_regsim_projects,
    replicate  text    not null,
    uuid       text    not null
        constraint version_uuid_fkey
            references job (uuid),
    constraint version_pkey
        primary key (version_no, uuid, regime_id, replicate)
);

alter table version
    owner to postgres;





    DROP TABLE glaciator_projects;
    DROP TABLE frappeator_projects;
    DROP TABLE frappe_projects;
    DROP TABLE frappeator_settings;
    DROP TABLE frost_auto_multi_project_regular;
    DROP TABLE frost_projects;
    DROP TABLE frost_scenarios;
    DROP TABLE frappe_multi_projects;
    DROP TABLE spacegrid;
    DROP TABLE gma_settings;
    DROP TABLE hydro_settings;
    DROP TABLE rusle_settings;
    DROP TABLE succession_settings;
    DROP TABLE multi_startup_fuel_info;
    DROP TABLE scenario;
    DROP TABLE version;


    DELETE FROM glaciator_projects;
    DELETE FROM frappeator_projects;
    DELETE FROM frappe_projects;
    DELETE FROM frappeator_settings;
    DELETE FROM frost_auto_multi_project_regular;
    DELETE FROM frost_projects;
    DELETE FROM frost_scenarios;
    DELETE FROM frappe_multi_projects;
    DELETE FROM spacegrid;
    DELETE FROM gma_settings;
    DELETE FROM hydro_settings;
    DELETE FROM rusle_settings;
    DELETE FROM succession_settings;
    DELETE FROM multi_startup_fuel_info;
    DELETE FROM scenario;
    DELETE FROM version;
