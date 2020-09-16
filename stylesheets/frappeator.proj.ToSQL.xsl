<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <xsl:template match="*/text()">
      <xsl:value-of select="replace(., '\\', '/')"/>
    </xsl:template>

    <xsl:template match="@*|node()">
      <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
    </xsl:template>





    <xsl:template match="/">
    <sqlgroup>
        <xsl:apply-templates select="frappeator_project"/>
    </sqlgroup>
    </xsl:template>

    <xsl:template match="frappeator_project">
        <sqlstatement
            table="frappeator_projects"
            action="CREATE">
            CREATE TABLE IF NOT EXISTS frappeator_projects (

                frappeator_project_id              BIGSERIAL,
                name                                TEXT     NOT NULL,
                version                             DECIMAL  NOT NULL,
                project_descr                       TEXT     NOT NULL,
                glaciator_output_results_root_dir_path TEXT  NOT NULL,
                frappeator_output_root_dir_path     TEXT     NOT NULL,
                frappe_exe_path                     TEXT     NOT NULL,
                is_frost_multi_proj                 BOOLEAN  NOT NULL,
                concurrent_threads                  INTEGER  NOT NULL,

                uuid                                TEXT     NOT NULL,
                PRIMARY KEY (frappeator_project_id, uuid, name),
                FOREIGN KEY (uuid) REFERENCES job (uuid)
            );
        </sqlstatement>

        <sqlstatement
            table="frappeator_projects"
            action="insert">
        INSERT INTO
            frappeator_projects
            (
                name,
                version,
                project_descr,
                glaciator_output_results_root_dir_path,
                frappeator_output_root_dir_path,
                frappe_exe_path,
                is_frost_multi_proj,
                concurrent_threads,
                uuid
            )
            VALUES
            (
                '<xsl:value-of select="project_name"/>',
                <xsl:value-of select="@version"/>,
                '<xsl:value-of select="project_descr"/>',
                '<xsl:value-of select="glaciator_output_results_root_dir_path"/>',
                '<xsl:value-of select="frappeator_output_root_dir_path"/>',
                '<xsl:value-of select="frappe_exe_path"/>',
                '<xsl:value-of select="is_frost_multi_proj"/>',
                <xsl:value-of select="concurrent_threads"/>,
                '<xsl:value-of select="//meta/uuid"/>'
            )
            RETURNING frappeator_project_id;
        </sqlstatement>
        <xsl:apply-templates select="frappe_multi_project"/>
        <xsl:apply-templates select="frappe_project_template_file"/>

    </xsl:template>

    <xsl:template match="frappe_multi_project">
        <sqlstatement
            table="frappe_multi_projects"
            action="CREATE">
            CREATE TABLE IF NOT EXISTS frappe_multi_projects (

                frappe_multi_project_id             BIGSERIAL,
                frost_output_results_dir_rel_path   TEXT     NOT NULL,
                frappe_project_file_id              BIGINT   NOT NULL,
                uuid                                TEXT     NOT NULL,
                PRIMARY KEY (frappe_multi_project_id)
            );
        </sqlstatement>

        <sqlstatement
            table="frappe_multi_projects"
            action="insert">
        INSERT INTO frappe_multi_projects
            (
                frost_output_results_dir_rel_path,
                frappe_project_file_id,
                uuid
            )
        VALUES
            (
                '<xsl:value-of select="glaciator_output_results_root_dir_path"/>',
                <xsl:value-of select="frappe_project_file_id"/>,
                '<xsl:value-of select="//meta/uuid"/>'
            )
        RETURNING frappe_multi_project_id;
        </sqlstatement>
    </xsl:template>

    <xsl:template match="frappe_project_template_file">
        <sqlstatement
            table="frappe_project_template_files"
            action="CREATE">
            CREATE TABLE IF NOT EXISTS frappe_project_template_files (

                frappe_project_template_files_id             BIGSERIAL,
                path                                        TEXT     NOT NULL,
                id                                          BIGINT   NOT NULL,
                uuid                                        TEXT     NOT NULL,
                PRIMARY KEY (frappe_project_template_files_id)
            );
        </sqlstatement>

        <sqlstatement
            table="frappe_project_template_files"
            action="insert">
        INSERT INTO frappe_project_template_files
            (
                id,
                path,
                uuid
            )
        VALUES
            (
                <xsl:value-of select="id"/>,
                '<xsl:value-of select="path"/>',
                '<xsl:value-of select="//meta/uuid"/>'
            )
        RETURNING frappe_project_template_files_id;
</sqlstatement>
</xsl:template>
</xsl:stylesheet>
