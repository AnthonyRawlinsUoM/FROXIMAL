<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <!-- <xsl:template match="*/text()">
      <xsl:value-of select="replace(., '\\', '/')"/>
    </xsl:template>

    <xsl:template match="@*|node()">
      <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
    </xsl:template> -->




<xsl:template match="/">
    <sqlgroup>
        <xsl:apply-templates select="frost_regsim_project"/>
    </sqlgroup>
    <!-- <xsl:apply-templates select="@*|node()"/> -->
</xsl:template>



<xsl:template match="frost_regsim_project">
    <sqlstatement
        table="frost_regsim_projects"
        action="CREATE">
        CREATE TABLE IF NOT EXISTS frost_regsim_projects (
          frost_regsim_project_id             BIGSERIAL,
          project_name                        TEXT         NOT NULL,
          version                             DECIMAL,
          project_descr                       TEXT,
          machines_in_files_root_dir          TEXT         NOT NULL,
          base_dataset_id                     INTEGER      NOT NULL,
          output_root_dir                     TEXT         NOT NULL,
          start_year_of_first_fireyear        INTEGER      NOT NULL,
          start_year_of_last_fireyear         INTEGER      NOT NULL,
          startup_fuel_info_id                INTEGER,

          uuid                                TEXT         NOT NULL,

          PRIMARY KEY (frost_regsim_project_id, uuid, project_name),

          FOREIGN KEY (uuid) REFERENCES job (uuid),
          FOREIGN KEY (startup_fuel_info_id)
                        REFERENCES startup_fuel_info (startup_fuel_info_id)
        );
    </sqlstatement>

    <sqlstatement
        table="frost_regsim_projects"
        action="insert">
    INSERT INTO
        frost_regsim_projects
        (
            project_name,
            version,
            project_descr,
            machines_in_files_root_dir,
            base_dataset_id,
            output_root_dir,
            start_year_of_first_fireyear,
            start_year_of_last_fireyear,
            uuid
        )
        VALUES
        (
            '<xsl:value-of select="project_name"/>',
            '<xsl:value-of select="@version"/>',
            '<xsl:value-of select="project_descr"/>',
            '<xsl:value-of select="machines_in_files_root_dir"/>',
            <xsl:value-of select="base_dataset_id"/>,
            '<xsl:value-of select="output_root_dir"/>',
            <xsl:value-of select="start_year_of_first_fireyear"/>,
            <xsl:value-of select="start_year_of_last_fireyear"/>,
            '<xsl:value-of select="//meta/uuid"/>'
        )
        RETURNING frost_regsim_project_id;
    </sqlstatement>
    <xsl:apply-templates select="startup_fuel_info"/>
</xsl:template>

<xsl:template match="startup_fuel_info">
    <sqlstatement
        table="startup_fuel_info"
        action="CREATE">
        CREATE TABLE IF NOT EXISTS startup_fuel_info (
          startup_fuel_info_id                BIGSERIAL,
          fire_history_zipgrid_filename       TEXT,
          current_in_year                     INTEGER,
          uses_fire_history                   BOOLEAN      NOT NULL,
          aligned_fire_history                BOOLEAN,
          uuid                                TEXT         NOT NULL,

          PRIMARY KEY (startup_fuel_info_id),
          FOREIGN KEY (uuid) REFERENCES job (uuid)
        );
    </sqlstatement>

    <xsl:choose>
	    <xsl:when test="uses_fire_history = 'true'">

            <sqlstatement
                table="startup_fuel_info"
                action="insert">
            INSERT INTO
                startup_fuel_info
                (
                    fire_history_zipgrid_filename,
                    current_in_year,
                    uses_fire_history,
                    aligned_fire_history,
                    uuid
                )
                VALUES
                (
                    '<xsl:value-of select="fire_history_zipgrid_filename"/>',
                    <xsl:value-of select="current_in_year"/>,
                    '<xsl:value-of select="uses_fire_history"/>',
                    '<xsl:value-of select="aligned_fire_history"/>',
                    '<xsl:value-of select="//meta/uuid"/>'
                )
                RETURNING startup_fuel_info_id;
            </sqlstatement>

        </xsl:when>

        <xsl:otherwise>

            <sqlstatement
                table="startup_fuel_info"
                action="insert">
            INSERT INTO
                startup_fuel_info
                (
                    uses_fire_history,
                    uuid
                )
                VALUES
                (
                    '<xsl:value-of select="uses_fire_history"/>',
                    '<xsl:value-of select="//meta/uuid"/>'
                )
                RETURNING startup_fuel_info_id;
            </sqlstatement>

        </xsl:otherwise>
    </xsl:choose>


</xsl:template>
</xsl:stylesheet>
