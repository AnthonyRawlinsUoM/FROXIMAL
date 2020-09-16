<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- <xsl:output
    method="text"
    version="string"
    encoding="string"
    omit-xml-declaration="no"
    standalone="yes"
    doctype-public="string"
    doctype-system="string"
    cdata-section-elements="
    glaciator_projects
    frappeator_settings
    frappe_project_template_file
    frost_auto_multi_project_regular
    multi_startup_fuel_info
    "
    indent="yes"
    media-type="text/sql"/> -->
    <!-- <xsl:output method="text"/> -->


    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <!-- <xsl:template match="*/text()">
      <xsl:value-of select="replace(., '\\', '/')"/>
    </xsl:template>

    <xsl:template match="@*|node()">
      <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
    </xsl:template> -->




    <xsl:template match="/">
    <sqlgroup>
        <xsl:apply-templates select="glaciator_project"/>
    </sqlgroup>
    </xsl:template>

    <xsl:template match="glaciator_project">

        <sqlstatement
            table="glaciator_projects"
            action="CREATE">
            CREATE TABLE IF NOT EXISTS glaciator_projects (
                glaciator_project_id        BIGSERIAL,
                name                        TEXT        NOT NULL,
                uuid                        TEXT        NOT NULL,
                version                     REAL        NOT NULL,
                glaciator_project_description   text    NOT NULL,
                PRIMARY KEY (glaciator_project_id),
                FOREIGN KEY (uuid) REFERENCES job (uuid)
            );
        </sqlstatement>

        <sqlstatement
            table="glaciator_projects"
            action="insert">
        INSERT INTO
            glaciator_projects
            (
                uuid,
                name,
                version,
                glaciator_project_description
            )
            VALUES
            (
                '<xsl:value-of select="//meta/uuid"/>',
                '<xsl:value-of select="glaciator_project_name"/>',
                '<xsl:value-of select="@version"/>',
                '<xsl:value-of select="glaciator_project_description"/>'
            )
            RETURNING glaciator_project_id;
        </sqlstatement>
        <xsl:apply-templates select="frappeator_settings"/>
        <xsl:apply-templates select="frost_auto_multi_project_regular"/>

    </xsl:template>

    <xsl:template match="frappeator_settings">
        <sqlstatement
            table="frappeator_settings"
            action="CREATE">
            CREATE TABLE IF NOT EXISTS frappeator_settings (
                frappeator_settings_id            BIGSERIAL,
                frappeator_output_root_dir_path   TEXT        NOT NULL,
                frappeator_exe_path               TEXT        NOT NULL,
                frappe_exe_path                   TEXT        NOT NULL,
                uuid                              TEXT        NOT NULL,
                run_frappeator                    BOOLEAN     NOT NULL,
                is_frost_multi_proj               BOOLEAN     NOT NULL,
                concurrent_threads                INTEGER     NOT NULL,
                PRIMARY KEY (frappeator_settings_id)
            );
        </sqlstatement>

        <sqlstatement
            table="frappeator_settings"
            action="insert">
        INSERT INTO
            frappeator_settings
        (
            run_frappeator,
            frappeator_output_root_dir_path,
            frappe_exe_path,
            is_frost_multi_proj,
            concurrent_threads,
            frappeator_exe_path,
            uuid
        )
        VALUES
        (
            '<xsl:value-of select="run_frappeator"/>',
            '<xsl:value-of select="frappeator_output_root_dir_path"/>',
            '<xsl:value-of select="frappe_exe_path"/>',
            '<xsl:value-of select="is_frost_multi_proj"/>',
            '<xsl:value-of select="concurrent_threads"/>',
            '<xsl:value-of select="frappeator_exe_path"/>',
            '<xsl:value-of select="//meta/uuid"/>'
        )
        RETURNING frappeator_settings_id;
        </sqlstatement>

        <xsl:apply-templates select="frappe_project_template_file"/>
    </xsl:template>

    <xsl:template match="frappe_project_template_file">

        <sqlstatement
            table="frappe_project_template_files"
            action="CREATE">
            CREATE TABLE IF NOT EXISTS frappe_project_template_files (
                frappe_project_template_files_id    BIGSERIAL,
                id                                  TEXT        NOT NULL,
                path                                TEXT        NOT NULL,
                uuid                                TEXT        NOT NULL,
                PRIMARY KEY (frappe_project_template_files_id)
            );
        </sqlstatement>

        <sqlstatement
            table="frappe_project_template_files"
            action="insert">
        INSERT INTO
            frappe_project_template_files
        (
            id,
            path,
            uuid
        )
        VALUES
        (
            '<xsl:value-of select="id"/>',
            '<xsl:value-of select="path"/>',
            '<xsl:value-of select="//meta/uuid"/>'
        )
        RETURNING frappe_project_template_files_id;
        </sqlstatement>

    </xsl:template>

    <xsl:template match="frost_auto_multi_project_regular">

        <sqlstatement
            table="frost_auto_multi_project_regular"
            action="CREATE">
            CREATE TABLE IF NOT EXISTS frost_auto_multi_project_regular (
                frost_auto_multi_project_regular_id    BIGSERIAL,
                multi_project_name                  TEXT        NOT NULL,
                machines_settings_file_id           INTEGER     NOT NULL,
                start_year_of_first_regsim_fireyear INTEGER     NOT NULL,
                regsim_duration_years               INTEGER     NOT NULL,
                years_between_regsims               INTEGER     NOT NULL,
                subproject_name_mask                TEXT        NOT NULL,
                output_dir_path                     TEXT        NOT NULL,
                regsim_index_start                  INTEGER     NOT NULL,
                regsim_index_end                    INTEGER     NOT NULL,
                frappe_project_template_file_id     BIGINT      NOT NULL,
                uuid                                TEXT        NOT NULL,

                PRIMARY KEY (frost_auto_multi_project_regular_id),
                FOREIGN KEY (uuid) REFERENCES job (uuid)
            );
        </sqlstatement>


        <sqlstatement
            table="frost_auto_multi_project_regular"
            action="insert">
        INSERT INTO
            frost_auto_multi_project_regular
        (
            multi_project_name,
            output_dir_path,
            machines_settings_file_id,
            start_year_of_first_regsim_fireyear,
            regsim_duration_years,
            years_between_regsims,
            subproject_name_mask,
            regsim_index_start,
            regsim_index_end,
            frappe_project_template_file_id,
            uuid
        )
        VALUES
        (
            '<xsl:value-of select="multi_project_name"/>',
            '<xsl:value-of select="output_dir_path"/>',
            '<xsl:value-of select="machines_settings_file_id"/>',
            '<xsl:value-of select="start_year_of_first_regsim_fireyear"/>',
            '<xsl:value-of select="regsim_duration_years"/>',
            '<xsl:value-of select="years_between_regsims"/>',
            '<xsl:value-of select="subproject_name_mask"/>',
            '<xsl:value-of select="regsim_index_start"/>',
            '<xsl:value-of select="regsim_index_end"/>',
            '<xsl:value-of select="frappe_project_template_file_id"/>',
            '<xsl:value-of select="//meta/uuid"/>'
        )
        RETURNING frost_auto_multi_project_regular_id;
        </sqlstatement>
        <xsl:apply-templates select="multi_startup_fuel_info"/>
    </xsl:template>

    <xsl:template match="multi_startup_fuel_info">

        <sqlstatement
            table="multi_startup_fuel_info"
            action="CREATE">
            CREATE TABLE IF NOT EXISTS multi_startup_fuel_info (
                multi_startup_fuel_info_id          BIGSERIAL,
                fire_history_zipgrid_filename       TEXT,
                aligned_fire_history                TEXT,
                uuid                                TEXT        NOT NULL,
                PRIMARY KEY (multi_startup_fuel_info_id)
            );
        </sqlstatement>


        <sqlstatement
            table="multi_startup_fuel_info"
            action="insert">
        INSERT INTO
            multi_startup_fuel_info
        (
            fire_history_zipgrid_filename,
            aligned_fire_history,
            uuid
        )
        VALUES
        (
            '<xsl:value-of select="fire_history_zipgrid_filename"/>',
            '<xsl:value-of select="aligned_fire_history"/>',
            '<xsl:value-of select="//meta/uuid"/>'
        )
        RETURNING multi_startup_fuel_info_id;
        </sqlstatement>
    </xsl:template>
</xsl:stylesheet>
