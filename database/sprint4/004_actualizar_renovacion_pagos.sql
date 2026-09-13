CREATE OR REPLACE PROCEDURE sp_registrar_pago(
    IN p_id_cliente integer,
    IN p_id_recepcionista integer,
    IN p_monto numeric,
    IN p_tipo character varying
)
LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO historial_pagos (
        id_cliente,
        id_recepcionista,
        monto_pagado,
        tipo_pago
    )
    VALUES (
        p_id_cliente,
        p_id_recepcionista,
        p_monto,
        p_tipo
    );

    IF p_tipo = 'Mensualidad' THEN

        UPDATE clientes
        SET fecha_pago_mensual =
            CASE
                WHEN fecha_pago_mensual IS NULL
                    THEN CURRENT_DATE

                WHEN fecha_pago_mensual + INTERVAL '1 month' > CURRENT_DATE
                    THEN fecha_pago_mensual + INTERVAL '1 month'

                ELSE CURRENT_DATE
            END
        WHERE id_cliente = p_id_cliente;

    ELSIF p_tipo = 'Anualidad' THEN

        UPDATE clientes
        SET fecha_pago_anualidad =
            CASE
                WHEN fecha_pago_anualidad IS NULL
                    THEN CURRENT_DATE

                WHEN fecha_pago_anualidad + INTERVAL '1 year' > CURRENT_DATE
                    THEN fecha_pago_anualidad + INTERVAL '1 year'

                ELSE CURRENT_DATE
            END
        WHERE id_cliente = p_id_cliente;

    END IF;
END;
$$;