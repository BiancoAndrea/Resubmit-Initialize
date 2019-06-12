-- CREATE SCHEMA

CREATE SCHEMA tibco_coll_maximo

--create sequence resubmit

CREATE SEQUENCE tibco_coll_maximo.resubmit_id_seq
    INCREMENT 1
    START 460
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

-- Table resubmit
CREATE TABLE tibco_coll_maximo.resubmit
(
    id integer NOT NULL DEFAULT nextval('tibco_coll_maximo.resubmit_id_seq'::regclass),
    data_ins date NOT NULL,
    data_mod date NOT NULL,
    num_retry integer NOT NULL,
    tipo_rich character varying(255) COLLATE pg_catalog."default",
    xml_rich text COLLATE pg_catalog."default",
    status character varying(255) COLLATE pg_catalog."default" NOT NULL,
    proc_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    doc_log_id numeric,
    bus_key character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT idx1_resubmit PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

-- Table resubmit_conf
CREATE TABLE tibco_coll_maximo.resubmit_conf
(
    tipo_rich character varying(255) COLLATE pg_catalog."default" NOT NULL,
    retry_num_max numeric NOT NULL,
    retry_freq numeric NOT NULL,
    not_id character varying(50) COLLATE pg_catalog."default",
    application character varying COLLATE pg_catalog."default" NOT NULL,
    version character varying COLLATE pg_catalog."default" NOT NULL,
    service character varying COLLATE pg_catalog."default" NOT NULL,
    appnode character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT idx1_resubmit_conf PRIMARY KEY (tipo_rich)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE tibco_coll_maximo.resubmit_conf
    OWNER to postgres;

--index IDX1
CREATE UNIQUE INDEX "IDX1_RESUBMIT"
    ON tibco_coll_maximo.resubmit USING btree
    (id)
    TABLESPACE pg_default;

-- Index IDX2_RESUBMIT
CREATE INDEX IDX2_RESUBMIT ON tibco_coll_maximo.RESUBMIT (NUM_RETRY, STATUS)
-- Index IDX3_RESUBMIT
CREATE INDEX IDX3_RESUBMIT ON tibco_coll_maximo.RESUBMIT (TIPO_RICH, NUM_RETRY, STATUS)
-- Index IDX4_RESUBMIT
CREATE INDEX IDX4_RESUBMIT ON tibco_coll_maximo.RESUBMIT (STATUS) 


--SET_resubmit
CREATE OR REPLACE FUNCTION tibco_coll_maximo.set_resubmit(
	p_id numeric,
	p_tipo_rich character varying,
	p_xml_rich text,
	p_status character varying,
	p_proc_name character varying,
	p_doc_log_id numeric,
	p_bus_key character varying)
    RETURNS tibco_coll_maximo.result
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$ 
DECLARE 
 P_CNT NUMERIC;
 P_date TIMESTAMP;
 response tibco_coll_maximo.result;
 
BEGIN
	response.p_out_desc:='Success';
	response.p_out_cod:='OK';
	P_date:=current_timestamp;
	
	IF (p_ID IS NOT NULL) THEN
		SELECT COUNT(*) INTO P_CNT FROM tibco_coll_maximo.resubmit WHERE ID =  p_ID;
		IF (P_CNT<1) THEN
        	INSERT INTO tibco_coll_maximo.resubmit (ID,DATA_INS,DATA_MOD,NUM_RETRY,TIPO_RICH,XML_RICH,STATUS,PROC_NAME,DOC_LOG_ID,BUS_KEY) 
			VALUES (p_ID,p_date,p_date,0,p_TIPO_RICH,p_XML_RICH,p_STATUS,p_PROC_NAME,p_DOC_LOG_ID,p_BUS_KEY);
        ELSE
       		UPDATE tibco_coll_maximo.resubmit set DATA_MOD = p_date,NUM_RETRY=NUM_RETRY+1 where ID = p_ID;
        END IF;
	ELSE
	INSERT INTO tibco_coll_maximo.RESUBMIT (DATA_INS,DATA_MOD,NUM_RETRY,TIPO_RICH,XML_RICH,STATUS,PROC_NAME,DOC_LOG_ID,BUS_KEY) 
				VALUES (p_date,p_date,0,p_TIPO_RICH,p_XML_RICH,p_STATUS,p_PROC_NAME,p_DOC_LOG_ID,p_BUS_KEY);
	END IF;
	RETURN response;
	EXCEPTION WHEN OTHERS THEN
			response.p_out_cod:='KO';
            response.p_out_desc:= concat('exception (code=', SQLCODE,'): ', SQLERRM);
	RETURN response;
END
$BODY$	
	
-- create setstatus	
	
CREATE OR REPLACE FUNCTION tibco_coll_maximo.set_status(
    IN p_id numeric,
    IN p_status text)
  RETURNS tibco_coll_maximo.result AS
$BODY$
DECLARE 
 p_date TIMESTAMP;
 response tibco_coll_maximo.result;
BEGIN
	response.p_out_cod:='OK';
	response.p_out_desc:='Success';
	p_date:=current_timestamp;
	IF(p_ID is not null) THEN
		UPDATE tibco_coll_maximo.resubmit set DATA_MOD = p_date,STATUS=p_STATUS  where ID = p_ID;
	END IF;
	RETURN response;
	EXCEPTION WHEN OTHERS THEN
	    response.p_out_cod:='KO';
            response.p_out_desc:= concat('exception (code=', SQLCODE,'): ', SQLERRM);
	RETURN response;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
ALTER FUNCTION tibco_coll_maximo.set_status(numeric, text)
    OWNER TO postgres;

-- create type

CREATE TYPE tibco_coll_maximo.result AS
(
	p_out_desc text,
	p_out_cod text
);