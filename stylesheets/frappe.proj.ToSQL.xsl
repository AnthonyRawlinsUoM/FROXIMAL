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
            <xsl:apply-templates select="frappe_project"/>
        </sqlgroup>
    </xsl:template>

<xsl:template match="frappe_project">
    <sqlstatement
        table="frappe_projects"
        action="CREATE">
        CREATE TABLE IF NOT EXISTS frappe_projects (
            frappe_project_id                  BIGSERIAL,
            project_name                        TEXT        NOT NULL,
            project_descr                       TEXT,
            frost_machinery_data_root_dir       TEXT        NOT NULL,
            frost_output_results_root_dir       TEXT        NOT NULL,
            frappe_output_results_root_dir      TEXT        NOT NULL,
            fuel_machine_type                   INTEGER,
            run_biodiversity                    BOOLEAN     NOT NULL,
            run_genasset                        BOOLEAN     NOT NULL,
            run_infrustruct                     BOOLEAN     NOT NULL,
            run_people_house_loss               BOOLEAN     NOT NULL,
            run_viewshed                        BOOLEAN     NOT NULL,
            run_carbon                          BOOLEAN     NOT NULL,
            run_pb_stat                         BOOLEAN     NOT NULL,

            uuid                                TEXT        NOT NULL,
            replicate                           TEXT        NOT NULL,
            regime                              TEXT        NOT NULL,

            succession_settings_id              BIGINT,
            hydro_settings_id                   BIGINT,
            gma_settings_id                     BIGINT,

            PRIMARY KEY (frappe_project_id),
            FOREIGN KEY (hydro_settings_id) REFERENCES hydro_settings (hydro_settings_id),
            FOREIGN KEY (gma_settings_id) REFERENCES gma_settings (gma_settings_id),
            FOREIGN KEY (succession_settings_id) REFERENCES succession_settings (succession_settings_id),

            FOREIGN KEY (replicate) REFERENCES frappeator_projects (name),
            FOREIGN KEY (regime) REFERENCES frost_auto_multi_project_regular (multi_project_name),
            FOREIGN KEY (uuid) REFERENCES job (uuid)
        );
    </sqlstatement>

    <sqlstatement
        table="frappe_projects"
        action="insert">
        INSERT INTO frappe_projects
            (
                project_name,
                project_descr,
                frost_machinery_data_root_dir,
                frost_output_results_root_dir,
                frappe_output_results_root_dir,
                fuel_machine_type,
                run_biodiversity,
                run_genasset,
                run_infrustruct,
                run_people_house_loss,
                run_viewshed,
                run_carbon,
                run_pb_stat,
                uuid,
                regime,
                replicate

            )
        VALUES
            (
                '<xsl:value-of select="project_name"/>',
                '<xsl:value-of select="project_descr"/>',
                '<xsl:value-of select="frost_machinery_data_root_dir"/>',
                '<xsl:value-of select="frost_output_results_root_dir"/>',
                '<xsl:value-of select="frappe_output_results_root_dir"/>',
                '<xsl:value-of select="fuel_machine_type"/>',
                '<xsl:value-of select="run_biodiversity"/>',
                '<xsl:value-of select="run_genasset"/>',
                '<xsl:value-of select="run_infrustruct"/>',
                '<xsl:value-of select="run_people_house_loss"/>',
                '<xsl:value-of select="run_viewshed"/>',
                '<xsl:value-of select="run_carbon"/>',
                '<xsl:value-of select="run_pb_stat"/>',
                '<xsl:value-of select="//meta/uuid"/>',
                <xsl:value-of select="//meta/regime"/>,
                '<xsl:value-of select="//meta/replicate"/>'
            )
        RETURNING frappe_project_id;
    </sqlstatement>
    <xsl:apply-templates select="hydro_settings"/>
    <xsl:apply-templates select="succession_settings"/>
    <xsl:apply-templates select="gma_settings"/>
</xsl:template>

<xsl:template match="hydro_settings">
    <sqlstatement
        table="hydro_settings"
        action="CREATE">
        CREATE TABLE IF NOT EXISTS hydro_settings (

            hydro_settings_id                   BIGSERIAL,
            run_hydro                           BOOLEAN     NOT NULL,
            uuid                                TEXT        NOT NULL,
            replicate                           TEXT        NOT NULL,
            regime                              TEXT        NOT NULL,
            PRIMARY KEY (hydro_settings_id),
            FOREIGN KEY (replicate) REFERENCES frappeator_projects (name),
            FOREIGN KEY (regime) REFERENCES frost_auto_multi_project_regular (multi_project_name),
            FOREIGN KEY (uuid) REFERENCES job (uuid)
        );
    </sqlstatement>

    <sqlstatement
        table="hydro_settings"
        action="insert">
        INSERT INTO hydro_settings
            (
                run_hydro,
                uuid,
                regime,
                replicate
            )
        VALUES
            (
                '<xsl:value-of select="project_name"/>'
                '<xsl:value-of select="//meta/uuid"/>',
                <xsl:value-of select="//meta/regime"/>,
                '<xsl:value-of select="//meta/replicate"/>'
            )
        RETURNING hydro_settings_id;
    </sqlstatement>

    <xsl:apply-templates select="rusle_settings"/>
</xsl:template>

<xsl:template match="rusle_settings">
    <sqlstatement
        table="rusle_settings"
        action="CREATE">
        CREATE TABLE IF NOT EXISTS rusle_settings (

            rusle_settings_id                   BIGSERIAL,
            c_peak                              DECIMAL     NOT NULL,
            c_harvpeak                          DECIMAL     NOT NULL,
            xic_fire                            DECIMAL     NOT NULL,
            xic_harv                            DECIMAL     NOT NULL,
            xik_harv                            DECIMAL     NOT NULL,
            k_fire_multiplier                   INTEGER     NOT NULL,
            k_harv_multiplier                   INTEGER     NOT NULL,
            r_climate                           DECIMAL     NOT NULL,
            weather_type                        BIGINT      NOT NULL,

            uuid                                TEXT        NOT NULL,
            replicate                           TEXT        NOT NULL,
            regime                              TEXT        NOT NULL,
            PRIMARY KEY (rusle_settings_id),

            FOREIGN KEY (replicate) REFERENCES frappeator_projects (name),
            FOREIGN KEY (regime) REFERENCES frost_auto_multi_project_regular (multi_project_name),
            FOREIGN KEY (uuid) REFERENCES job (uuid)
        );
    </sqlstatement>

    <sqlstatement
        table="rusle_settings"
        action="insert">
        INSERT INTO rusle_settings
            (
                c_peak,
                c_harvpeak,
                xic_fire,
                xic_harv,
                xik_harv,
                k_fire_multiplier,
                k_harv_multiplier,
                r_climate,
                weather_type,
                uuid,
                regime,
                replicate
            )
        VALUES
            (
                <xsl:value-of select="c_peak"/>,
                <xsl:value-of select="c_harvpeak"/>,
                <xsl:value-of select="xic_fire"/>,
                <xsl:value-of select="xik_fire"/>,
                <xsl:value-of select="xic_harv"/>,
                <xsl:value-of select="xik_harv"/>,
                <xsl:value-of select="k_fire_multiplier"/>,
                <xsl:value-of select="k_harv_multiplier"/>,
                '<xsl:value-of select="r_climate"/>',
                '<xsl:value-of select="weather_type"/>'
                '<xsl:value-of select="//meta/uuid"/>',
                <xsl:value-of select="//meta/regime"/>,
                '<xsl:value-of select="//meta/replicate"/>'
            )
        RETURNING rusle_settings_id;
    </sqlstatement>
</xsl:template>

<xsl:template match="succession_settings">

    <sqlstatement
        table="succession_settings"
        action="CREATE">
        CREATE TABLE IF NOT EXISTS succession_settings (

            succession_settings_id              BIGSERIAL,
            landis_data_available               BOOLEAN     NOT NULL,
            harvest_data_available              BOOLEAN     NOT NULL,

            run_biomass                         BOOLEAN     NOT NULL,
            run_harvest                         BOOLEAN     NOT NULL,
            run_hcv                             BOOLEAN     NOT NULL,
            run_carbon_landis                   BOOLEAN     NOT NULL,

            uuid                                TEXT        NOT NULL,
            replicate                           TEXT        NOT NULL,
            regime                              TEXT        NOT NULL,

            PRIMARY KEY (succession_settings_id),
            FOREIGN KEY (replicate) REFERENCES frappeator_projects (name),
            FOREIGN KEY (regime) REFERENCES frost_auto_multi_project_regular (multi_project_name),
            FOREIGN KEY (uuid) REFERENCES job (uuid)
        );
    </sqlstatement>

    <sqlstatement
        table="succession_settings"
        action="insert">
        INSERT INTO succession_settings
            (
                landis_data_available,
                harvest_data_available,
                run_biomass,
                run_harvest,
                run_hcv,
                run_carbon_landis,
                uuid,
                regime,
                replicate
            )
        VALUES
            (
                '<xsl:value-of select="landis_data_available"/>',
                '<xsl:value-of select="harvest_data_available"/>',
                '<xsl:value-of select="run_biomass"/>',
                '<xsl:value-of select="run_harvest"/>',
                '<xsl:value-of select="run_hcv"/>',
                '<xsl:value-of select="run_carbon_landis"/>'
                '<xsl:value-of select="//meta/uuid"/>',
                <xsl:value-of select="//meta/regime"/>,
                '<xsl:value-of select="//meta/replicate"/>'
            )
        RETURNING succession_settings_id;
    </sqlstatement>
</xsl:template>

<xsl:template match="gma_settings">

    <sqlstatement
        table="gma_settings"
        action="CREATE">
        CREATE TABLE IF NOT EXISTS gma_settings (

            succession_settings_id              BIGSERIAL,
            run_gma                             BOOLEAN     NOT NULL,
            run_age_distr_gma_detached          BOOLEAN     NOT NULL,

            uuid                                TEXT        NOT NULL,
            replicate                           TEXT        NOT NULL,
            regime                              TEXT        NOT NULL,

            PRIMARY KEY (succession_settings_id),
            FOREIGN KEY (replicate) REFERENCES frappeator_projects (name),
            FOREIGN KEY (regime) REFERENCES frost_auto_multi_project_regular (multi_project_name),
            FOREIGN KEY (uuid) REFERENCES job (uuid)
        );
    </sqlstatement>

    <sqlstatement
        table="gma_settings"
        action="insert">
        INSERT INTO gma_settings
            (
                run_gma,
                run_age_distr_gma_detached,
                uuid,
                regime,
                replicate
            )
        VALUES
            (
                '<xsl:value-of select="run_gma"/>',
                '<xsl:value-of select="run_age_distr_gma_detached"/>',
                '<xsl:value-of select="//meta/uuid"/>',
                <xsl:value-of select="//meta/regime"/>,
                '<xsl:value-of select="//meta/replicate"/>'
            )
        RETURNING gma_settings_id;
    </sqlstatement>
</xsl:template>

</xsl:stylesheet>
