drop table jobtojobstate;
drop table jobstate;
drop table replicates;
drop table regimes;
drop table job;
drop table fuel_machine_type;


create table job (
    id                                           INTEGER,
    name                                         INTEGER,
    descr                                        TEXT,
    uuid                                         TEXT,
    submission_time                              TIMESTAMP,
    submitter_name                               TEXT,
    submitter_email                              TEXT,
    weather_machine_kind                         INTEGER,
    fuel_machine_kind                            INTEGER,
    fire_history_kind                            INTEGER,
    planburn_target_perc                         REAL,
    harvesting_on                                BOOLEAN,
    regsim_duration                              REAL,
    num_replicates                               INTEGER,
    unique(uuid),
    constraint job_pk
        primary key (id)
);



create table jobstate (
    id                                           INTEGER,
    status                                       INTEGER     NOT NULL,
    machine_name                                 TEXT        NOT NULL,
    simulation_start_time                        TIMESTAMP   NOT NULL,
    simulation_warnings                          TEXT,
    simulation_results_dir_path                  TEXT,
    post_proc_start_time                         TIMESTAMP,
    post_proc_warnings                           TEXT,
    post_proc_results_dir_path                   TEXT,
    job_failure_time                             TIMESTAMP,
    job_completion_time                          TIMESTAMP,
    job_failure_error_message                    TEXT,
    published                                    BOOLEAN     NOT NULL DEFAULT FALSE,
    constraint jobstate_pk
        primary key (id)
);


create table jobtojobstate (
    job_id                                       INTEGER     NOT NULL,
    job_state_id                                 INTEGER     NOT NULL,
    foreign key (job_id) references job,
    foreign key (job_state_id) references jobstate
);


create table fuel_machine_type (
    fuel_machine_type_id                         INTEGER     NOT NULL,
    name                                         TEXT        NOT NULL,
    primary key (fuel_machine_type_id)
);


create table regimes (
    regime_id                                    INTEGER     NOT NULL,
    regime_path                                  TEXT        NOT NULL,
    version                                      INTEGER     NOT NULL,
    project_name                                 TEXT        NOT NULL,
    project_descr                                TEXT        NOT NULL,
    glaciator_output_results_root_dir_path       TEXT        NOT NULL,
    frappeator_output_root_dir_path              TEXT        NOT NULL,
    frappe_exe_path                              TEXT        NOT NULL,
    is_frost_multi_proj                          BOOLEAN     NOT NULL,
    concurrent_threads                           INTEGER,
    fuel_machine_type                            INTEGER,
    uuid                                         TEXT        NOT NULL,
    primary key (regime_id),
    unique (regime_id),
    foreign key (fuel_machine_type) references fuel_machine_type,
    constraint regimes_job_uuid_fk
        foreign key (uuid) references job (uuid)
);


create table replicates
(
    replicate_id                                 INTEGER     NOT NULL,
    replicate                                    TEXT        NOT NULL,
    regime_id                                    INTEGER     NOT NULL,
    primary key (replicate_id),
    unique (replicate_id),
    foreign key (regime_id) references regimes
        on update cascade on delete cascade
);


-- DROP TABLE public.fuel_machine_type CASCADE;

CREATE TABLE IF NOT EXISTS frappe_projects (
    frappe_project_id                            BIGSERIAL,
    version                                      INTEGER      NOT NULL,
    project_name                                 TEXT         NOT NULL,
    project_descr                                TEXT         NOT NULL,
    frost_machinery_data_root_dir                TEXT         NOT NULL,
    frost_output_results_root_dir                TEXT         NOT NULL,
    frappe_output_results_root_dir               TEXT         NOT NULL,

    fuel_machine_type_id                         INTEGER,

    run_biodiversity                             BOOLEAN      NOT NULL,
    run_genasset                                 BOOLEAN      NOT NULL,
    run_infrustruct                              BOOLEAN      NOT NULL,
    run_people_house_loss                        BOOLEAN      NOT NULL,
    run_viewshed                                 BOOLEAN      NOT NULL,
    run_carbon                                   BOOLEAN      NOT NULL,
    run_pb_stat                                  BOOLEAN      NOT NULL,

    hydro_settings_id                            INTEGER,
    gma_settings_id                              INTEGER,
    succession_settings_id                       INTEGER,

    uuid                                         TEXT         NOT NULL,

    PRIMARY KEY(frappe_project_id));

CREATE TABLE IF NOT EXISTS rusle_settings (
    rusle_settings_id                            BIGSERIAL,
    c_peak                                       DECIMAL,
    c_harvpeak                                   DECIMAL,
    xic_fire                                     DECIMAL,
    xik_fire                                     DECIMAL,
    xic_harv                                     DECIMAL,
    xik_harv                                     DECIMAL,
    k_fire_multiplier                            DECIMAL,
    k_harv_multiplier                            DECIMAL,
    r_climate                                    DECIMAL,
    weather_type                                 TEXT,
    PRIMARY KEY(rusle_settings_id));

CREATE TABLE IF NOT EXISTS hydro_settings (
    hydro_settings_id                            BIGSERIAL,
    rusle_settings_id                            INTEGER,
    run_hydro                                    BOOLEAN      NOT NULL,
    PRIMARY KEY(hydro_settings_id));

CREATE TABLE IF NOT EXISTS succession_settings (
    succession_settings_id                       BIGSERIAL,
    landis_data_available                        BOOLEAN,
    harvest_data_available                       BOOLEAN,
    run_biomass                                  BOOLEAN      NOT NULL,
    run_harvest                                  BOOLEAN      NOT NULL,
    run_hcv                                      BOOLEAN      NOT NULL,
    run_carbon_landis                            BOOLEAN      NOT NULL,
    PRIMARY KEY(succession_settings_id));

CREATE TABLE IF NOT EXISTS gma_settings (
    gma_settings_id                             BIGSERIAL,
    run_gma                                      BOOLEAN      NOT NULL,
    run_age_distr_gma_detached                   BOOLEAN      NOT NULL,
	PRIMARY KEY(gma_settings_id));

CREATE TABLE IF NOT EXISTS fuel_machine_type (
    fuel_machine_type_id                        SERIAL,
    name                                         TEXT         NOT NULL,
    PRIMARY KEY(fuel_machine_type_id));
