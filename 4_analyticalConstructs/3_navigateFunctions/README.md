#  Navegando Datos con SQL: Dominando `LEAD`, `LAG` y Más 🚢

Explora las funciones de ventana de navegación de SQL (`LEAD`, `LAG`) para acceder a datos de filas anteriores o posteriores dentro de tu conjunto de resultados. Esta guía cubre sus significados, ventajas, desventajas potenciales, alternativas ineficientes y culmina en problemas complejos que combinan estos conceptos con otras características de SQL.

---

## 1. Práctica de Significados, Valores, Relaciones y Ventajas

### Ejercicio 1.1: Próximo Monto de Ventas por Empleado

> **Problema:** Para cada registro de rendimiento, muestra el nombre del empleado, la fecha de la métrica, el monto de ventas actual y el monto de ventas de su registro de rendimiento inmediatamente posterior. Ordena los resultados por nombre de empleado y luego por fecha de métrica.
>
> **`LEAD(expresión [, offset [, default]]) OVER ( [PARTITION BY ...] ORDER BY ... )`**: Accede a los datos de una fila posterior dentro de la partición actual.
> **Ventaja:** Permite comparaciones directas con datos de "la siguiente" fila sin necesidad de auto-joins complejos o subconsultas correlacionadas.

```sql
SELECT
    employee_name,
    metric_date,
    sales_amount AS current_sales,
    LEAD(sales_amount, 1, NULL) OVER (PARTITION BY employee_name ORDER BY metric_date) AS next_sales
    -- PARTITION BY employee_name es crucial para obtener el "siguiente" para ESE empleado.
    -- El fragmento original omitió PARTITION BY, lo que daría el siguiente registro globalmente según metric_date.
FROM navigate_functions.employee_performance
ORDER BY employee_name, metric_date;
```

### Ejercicio 1.2: Tareas Anteriores Completadas por Empleado dentro del Departamento con Valor por Defecto

> **Problema:** Para cada registro de rendimiento, muestra el departamento, nombre del empleado, fecha de la métrica, tareas completadas actuales y las tareas completadas de su registro de rendimiento inmediatamente anterior dentro del mismo departamento. Si no hay registro anterior para ese empleado en ese departamento, muestra 0 para tareas anteriores. Ordena por departamento, nombre de empleado y fecha de métrica.
>
> **`LAG(expresión [, offset [, default]]) OVER ( [PARTITION BY ...] ORDER BY ... )`**: Accede a los datos de una fila anterior dentro de la partición actual. El argumento `default` es útil para manejar el primer registro de una partición.
> **Ventaja:** Similar a `LEAD`, simplifica las comparaciones con datos de "la fila anterior".

```sql
SELECT
    department,
    employee_name,
    metric_date,
    tasks_completed AS current_tasks,
    LAG(tasks_completed, 1, 0) OVER (PARTITION BY department, employee_name ORDER BY metric_date) AS previous_tasks
    -- PARTITION BY department, employee_name es necesario.
    -- El fragmento original omitió PARTITION BY, lo que daría el registro anterior globalmente según metric_date.
FROM navigate_functions.employee_performance
ORDER BY department, employee_name, metric_date;
```

### Ejercicio 1.3: Mirada Retrospectiva y Prospectiva de Ventas para un Empleado Específico

> **Problema:** Para 'Alice Smith', muestra su fecha de métrica, monto de ventas actual, el monto de ventas de dos registros de rendimiento anteriores y el monto de ventas de dos registros de rendimiento posteriores. Si dichos registros no existen, sus valores deben ser NULL. Ordena por fecha de métrica.
>
> **Ventaja:** El parámetro `offset` en `LEAD` y `LAG` permite mirar más allá de la fila inmediatamente adyacente.

```sql
SELECT
    metric_date,
    sales_amount AS current_sales,
    LAG(sales_amount, 2, NULL) OVER (ORDER BY metric_date) AS two_records_prior_sales, -- Asume que es solo para Alice
    LEAD(sales_amount, 2, NULL) OVER (ORDER BY metric_date) AS two_records_ahead_sales -- Asume que es solo para Alice
FROM navigate_functions.employee_performance
WHERE employee_name = 'Alice Smith'
ORDER BY metric_date; -- El ORDER BY final es importante para la presentación
```

### Ejercicio 1.4: Fecha de la Próxima Entrada de Rendimiento

> **Problema:** Para cada registro de rendimiento, muestra el nombre del empleado, la fecha de métrica actual y la fecha de su próxima entrada de rendimiento. Si no hay próxima entrada, muestra NULL. Ordena por nombre de empleado y luego por fecha de métrica actual.
>
> **Ventaja:** Se puede usar `LEAD` o `LAG` en cualquier tipo de columna, incluidas las fechas.

```sql
SELECT
    employee_name,
    metric_date AS current_metric_date,
    LEAD(metric_date, 1, NULL) OVER (PARTITION BY employee_name ORDER BY metric_date) AS next_entry_metric_date
    -- PARTITION BY employee_name es crucial.
    -- El fragmento original omitió PARTITION BY.
FROM navigate_functions.employee_performance
ORDER BY employee_name, metric_date;
```

---

## 2. Práctica de Desventajas de los Conceptos Técnicos

### Ejercicio 2.1: Manejo de NULLs de `LAG` en los Límites de la Partición

> **Problema:** Para cada registro de rendimiento, muestra nombre, fecha, ventas actuales y ventas del registro anterior. Calcula la diferencia (ventas actuales - ventas anteriores). Observa los NULLs para el primer registro de cada empleado y cómo afecta el cálculo de la diferencia. Ordena por nombre de empleado, luego fecha de métrica.
>
> **Desventaja/Consideración:** `LAG` (y `LEAD`) devuelven `NULL` (o el valor por defecto especificado) cuando no hay una fila anterior/posterior dentro de la partición. Cualquier cálculo aritmético que involucre este `NULL` resultará en `NULL`.

```sql
SELECT
    sq.*,
    sq.current_sales - sq.previous_sales AS lag_difference
FROM (
    SELECT
        employee_name,
        metric_date,
        sales_amount AS current_sales,
        LAG(sales_amount, 1, NULL) OVER (PARTITION BY employee_name ORDER BY metric_date) AS previous_sales
        -- PARTITION BY employee_name es crucial aquí. El fragmento original lo omitió, lo que significa que
        -- previous_sales sería el registro anterior globalmente, no por empleado.
    FROM analytical_cons_navigate_functions.employee_performance
) AS sq
ORDER BY sq.employee_name, sq.metric_date;
```
> **Explicación del fragmento:** Null is reproduced in lag_difference. *(Correcto, si `previous_sales` es `NULL`, la diferencia será `NULL`.)*

### Ejercicio 2.2: Impacto de un `ORDER BY` Incorrecto en la Cláusula `OVER()`

> **Problema:** Muestra los registros de 'Alice Smith' con fecha, tareas completadas y "próximas tareas correctas" (`LEAD` con `ORDER BY metric_date ASC`). Luego, muestra "próximas tareas incorrectas" usando erróneamente `ORDER BY metric_date DESC` en `LEAD`. Observa cómo esto último ahora representa las tareas del registro cronológico *anterior*.
>
> **Desventaja/Error Común:** El `ORDER BY` dentro de la cláusula `OVER()` define la noción de "anterior" y "posterior". Un `ORDER BY` incorrecto dará lugar a que `LEAD` y `LAG` recuperen datos de filas inesperadas.

**Orden Correcto para `LEAD` (para obtener el siguiente cronológico):**
```sql
SELECT
    metric_date,
    tasks_completed,
    LEAD(tasks_completed, 1, NULL) OVER (ORDER BY metric_date ASC) AS next_tasks_correct_order
FROM analytical_cons_navigate_functions.employee_performance
WHERE employee_name = 'Alice Smith'
ORDER BY metric_date ASC;
```

**Orden Incorrecto para `LEAD` (tratando de obtener el siguiente cronológico, pero `DESC` invierte la lógica):**
```sql
SELECT
    metric_date,
    tasks_completed,
    LEAD(tasks_completed, 1, NULL) OVER (ORDER BY metric_date DESC) AS next_tasks_looks_like_previous
FROM analytical_cons_navigate_functions.employee_performance
WHERE employee_name = 'Alice Smith'
ORDER BY metric_date ASC; -- El ORDER BY final es para presentación, el OVER() determina LEAD
```
> **Explicación del fragmento:** Clearly the query is counterintuitive, for a counterintuitive query.
> Si se usa `ORDER BY metric_date DESC` con `LEAD`, "siguiente" significa la fila que viene *antes* en el tiempo si se mira el conjunto de datos ordenado de forma descendente. Si el resultado final se ordena `ASC`, este valor de `LEAD` parecerá el `LAG`.

### Ejercicio 2.3: Impacto de Omitir `PARTITION BY`

> **Problema:** Para 'Bob Johnson', recupera su fecha de métrica, monto de ventas y el monto de ventas anterior (usando `LAG` particionado por `employee_id`). También recupera el monto de ventas anterior sin particionar (usando `LAG` *sin* `PARTITION BY employee_id`, pero aún ordenado por `employee_id`, `metric_date` globalmente). Compara.
>
> **Desventaja/Confusión:** Si se omite `PARTITION BY` cuando la lógica requiere un cálculo por grupo (p. ej., por empleado), `LAG`/`LEAD` operarán sobre todo el conjunto de resultados definido por `ORDER BY`. Esto puede llevar a que la fila "anterior" o "siguiente" pertenezca a un grupo diferente, lo cual suele ser incorrecto.

```sql
SELECT
    employee_name, -- Added for clarity
    metric_date,
    sales_amount,
    LAG(sales_amount, 1, NULL) OVER (PARTITION BY employee_id ORDER BY metric_date) AS previous_sales_partitioned,
    LAG(sales_amount, 1, NULL) OVER (ORDER BY employee_name, metric_date) AS previous_sales_unpartitioned
    -- El fragmento original tenía ORDER BY employee_id en el no particionado. Para que esto tenga sentido
    -- y sea comparable, el orden global debe incluir el empleado y luego la fecha.
FROM analytical_cons_navigate_functions.employee_performance
WHERE employee_name = 'Bob Johnson'
ORDER BY metric_date;
```
> **Explicación del fragmento (parcialmente correcta):** The result is the same because a partition over an independent space (employee_id) is the same to an ordering. This leads to two ways to do the same, misleading concepts up to confusion.
> **Clarificación:** El resultado *no* será el mismo para el primer registro de Bob Johnson si hay otros empleados antes que él en el orden global.
> *   `previous_sales_partitioned`: Para el primer registro de Bob, esto será `NULL` (o el valor por defecto).
> *   `previous_sales_unpartitioned`: Para el primer registro de Bob, si hay otro empleado (p. ej., Alice) cuyo último registro viene justo antes del primero de Bob en el orden global (`employee_name, metric_date`), entonces `previous_sales_unpartitioned` tomará el valor del último registro de Alice. Esto es generalmente incorrecto si se desea el LAG *dentro del mismo empleado*.
> El fragmento está en lo cierto en que puede llevar a confusión si no se entiende el alcance de `PARTITION BY`.

---

## 3. Práctica de Casos de Alternativas Ineficientes

### Ejercicio 3.1: Encontrar Eficientemente el Monto de Ventas Anterior

> **Problema:** Para cada registro de rendimiento del empleado, encuentra el monto de ventas de su registro inmediatamente anterior. `LAG` es eficiente. Una alternativa ineficiente podría involucrar una subconsulta correlacionada. Muestra ambas formas.
>
> **Ventaja de `LAG`:** Mucho más eficiente y legible que las subconsultas correlacionadas o auto-joins complejos para este tipo de tarea.

**Alternativa Ineficiente (usando DENSE_RANK y self-join, como en el fragmento):**
```sql
WITH RankedPerformance AS ( -- Renombrado desde "subquery"
    SELECT
        perf_id, employee_id, employee_name, metric_date, sales_amount, -- employee_name añadido para claridad
        DENSE_RANK() OVER (PARTITION BY employee_id ORDER BY metric_date ASC) AS ranking
    FROM navigate_functions.employee_performance
)
SELECT
    s1.employee_name, s1.metric_date, s1.sales_amount AS current_sales,
    s2.sales_amount AS previous_sales_inefficient
FROM RankedPerformance s1
LEFT JOIN RankedPerformance s2 -- LEFT JOIN para manejar el primer registro
    ON s1.employee_id = s2.employee_id AND s1.ranking = s2.ranking + 1 -- Corregido: s1.ranking = s2.ranking + 1
ORDER BY s1.employee_id, s1.metric_date;
-- El fragmento tenía s1.ranking = s2.ranking - 1, lo que buscaría el "siguiente". Para "anterior", el rango de s1 debe ser uno más que s2.
```

**Solución Eficiente (`LAG`):**
```sql
SELECT
    employee_id,
    employee_name,
    metric_date,
    sales_amount AS current_sales,
    LAG(sales_amount, 1, NULL) OVER (PARTITION BY employee_id ORDER BY metric_date ASC) AS previous_sales_efficient
FROM navigate_functions.employee_performance
ORDER BY employee_id, metric_date ASC;
```

### Ejercicio 3.2: Encontrar Eficientemente la Fecha del Siguiente Registro

> **Problema:** Para cada registro de rendimiento del empleado, encuentra la fecha de métrica de su siguiente registro. `LEAD` es eficiente. Una alternativa ineficiente podría ser una subconsulta correlacionada `(SELECT MIN(ep2.metric_date) ... WHERE ep2.metric_date > ep1.metric_date)`. Muestra la solución eficiente con `LEAD`.
>
> **Ventaja de `LEAD`:** Similar a `LAG`, es mucho más eficiente y directo.

**Solución Eficiente (`LEAD`):**
```sql
SELECT
    employee_id,
    employee_name,
    sales_amount, -- Incluido como en el fragmento, aunque no es el foco
    metric_date AS current_date_,
    LEAD(metric_date, 1, NULL) OVER (PARTITION BY employee_id ORDER BY metric_date ASC) AS next_date
FROM navigate_functions.employee_performance
ORDER BY employee_id, current_date_;
```

### Ejercicio 3.3: Identificar Eficientemente Aumentos de Ventas

> **Problem:** Identifica todos los registros de rendimiento donde el monto de ventas de un empleado fue mayor que el monto de ventas en su registro inmediatamente anterior para ese mismo empleado. Usar `LAG` dentro de una CTE o subconsulta es eficiente.
>
> **Ventaja de `LAG` en CTE/Subconsulta:** Permite calcular el valor anterior y luego filtrar basándose en él en una cláusula `WHERE` externa.

```sql
SELECT
    sq.*,
    (sq.current_sales > sq.previous_sales) AS is_better -- is_better ya está filtrado por el WHERE
FROM (
    SELECT
        employee_id,
        employee_name,
        metric_date,
        sales_amount AS current_sales,
        LAG(sales_amount, 1, NULL) OVER (PARTITION BY employee_id ORDER BY metric_date) AS previous_sales
    FROM navigate_functions.employee_performance
    -- ORDER BY employee_id, metric_date -- No es necesario aquí, solo en el exterior
) AS sq
WHERE sq.current_sales > sq.previous_sales -- Filtrar donde las ventas actuales son mayores
ORDER BY sq.employee_id, sq.metric_date; -- Ordenar el resultado final
```
*El fragmento ya es eficiente y correcto en su estructura.*

---

## 4. Problema Complejo Combinando Conceptos

### Ejercicio 4.1: Análisis de Rachas de Ventas de Empleados y Comparación Mensual

> **Problema:** Para cada empleado en el departamento de 'Ventas':
> 1.  Nombre, fecha, ventas actuales.
> 2.  Ventas anteriores (`LAG`) y siguientes (`LEAD`). Por defecto, ventas anteriores a 0.
> 3.  `is_increase` (booleano): ventas actuales > ventas anteriores.
> 4.  `streak_group_id`: Nuevo ID de racha si `is_increase` es true y el anterior no lo era (o es el primero y es un aumento sobre 0).
> 5.  `running_sales_in_streak`: Ventas acumuladas dentro de la racha actual.
> 6.  `avg_monthly_sales_for_employee`: Promedio de ventas del empleado para el mes calendario de la fecha de la métrica.
> 7.  `sales_rank_overall`: `DENSE_RANK()` del empleado basado en su registro de ventas individual más alto.
> Ordena por nombre de empleado, luego fecha de métrica.

*(El fragmento proporcionado usa una CTE recursiva para `streak_group_id`, lo cual es un enfoque avanzado y puede ser complejo. Un enfoque más común para la identificación de rachas (grupos de Gaps-and-Islands) es sumar un marcador que cambia cuando la condición de la racha se rompe).*

**Enfoque Refinado (conceptual):**

```sql
WITH SalesData AS (
    SELECT
        employee_id,
        employee_name,
        metric_date,
        department,
        sales_amount AS current_sales,
        LAG(sales_amount, 1, 0) OVER (PARTITION BY employee_id ORDER BY metric_date) AS previous_sales,
        LEAD(sales_amount, 1, NULL) OVER (PARTITION BY employee_id ORDER BY metric_date) AS next_sales
    FROM analytical_cons_navigate_functions.employee_performance
    WHERE department = 'Sales'
),
SalesIncreaseFlags AS (
    SELECT
        *,
        (current_sales > previous_sales) AS is_increase,
        LAG(current_sales > previous_sales, 1, FALSE) OVER (PARTITION BY employee_id ORDER BY metric_date) AS prev_is_increase
    FROM SalesData
),
StreakGroupCalculation AS (
    SELECT
        *,
        SUM(CASE WHEN is_increase = TRUE AND (prev_is_increase = FALSE OR prev_is_increase IS NULL) THEN 1 ELSE 0 END)
            OVER (PARTITION BY employee_id ORDER BY metric_date ROWS UNBOUNDED PRECEDING) AS streak_group_id
    FROM SalesIncreaseFlags
),
RunningSalesInStreak AS (
    SELECT
        *,
        SUM(CASE WHEN is_increase THEN current_sales ELSE 0 END) -- Sum only if it's part of an increasing streak
            OVER (PARTITION BY employee_id, streak_group_id ORDER BY metric_date ROWS UNBOUNDED PRECEDING) AS running_sales_in_streak
    FROM StreakGroupCalculation
),
MonthlyAvgSales AS (
    SELECT
        employee_id,
        DATE_TRUNC('month', metric_date) AS sale_month,
        AVG(sales_amount) AS avg_monthly_sales_for_employee
    FROM analytical_cons_navigate_functions.employee_performance
    WHERE department = 'Sales' -- Redundante si se une a SalesData, pero seguro
    GROUP BY employee_id, DATE_TRUNC('month', metric_date)
),
EmployeeMaxSale AS (
    SELECT
        employee_id,
        MAX(sales_amount) AS max_single_sale
    FROM analytical_cons_navigate_functions.employee_performance
    WHERE department = 'Sales'
    GROUP BY employee_id
),
OverallSalesRank AS (
    SELECT
        employee_id,
        DENSE_RANK() OVER (ORDER BY max_single_sale DESC) AS sales_rank_overall
    FROM EmployeeMaxSale
)
SELECT
    rsis.employee_name,
    rsis.metric_date,
    rsis.current_sales,
    rsis.previous_sales,
    rsis.next_sales,
    rsis.is_increase,
    rsis.streak_group_id,
    rsis.running_sales_in_streak,
    mas.avg_monthly_sales_for_employee,
    osr.sales_rank_overall
FROM RunningSalesInStreak rsis
LEFT JOIN MonthlyAvgSales mas
    ON rsis.employee_id = mas.employee_id AND DATE_TRUNC('month', rsis.metric_date) = mas.sale_month
LEFT JOIN OverallSalesRank osr
    ON rsis.employee_id = osr.employee_id
ORDER BY rsis.employee_name, rsis.metric_date;
```

**Crítica del Fragmento de Ejercicio 4.1:**
*   **`slicer` CTE:** Correctamente usa `LAG` y `LEAD`.
*   **`binary_peaks` CTE:** Determina `is_better` (is_increase).
*   **`identified_peaks` CTE:** Añade `peak_id` (un row_number global).
*   **`recursive_grouping` CTE:** Intenta calcular `streak_group_id` de forma recursiva. La lógica `CASE WHEN ip.is_better IS TRUE AND rg.is_better IS TRUE THEN rg.streak_group_id ... ELSE rg.streak_group_id` podría simplificarse. El enfoque de "sumar un marcador" es generalmente más sencillo para este tipo de agrupamiento de rachas.
*   **`grouped_for_rankings` CTE:** Prepara datos para el ranking de picos.
*   **`ranked_peaks` CTE:** Calcula `cumulative_sales` dentro de los picos (rachas de aumento).
*   **Final `SELECT`:**
    *   Une `grouped_for_rankings` con `ranked_peaks` y un `LATERAL` para `avg_monthly_sales_for_employee`.
    *   El `LATERAL` para el promedio mensual es una forma válida de obtenerlo por empleado y mes.
    *   `DENSE_RANK() OVER(PARTITION BY g.employee_id ORDER BY g.current_sales)`: El problema pedía "sales rank *overall* to each employee based on their *highest single sales amount* record". Esto significa que primero se debe encontrar la venta más alta de cada empleado, y luego rankear a los empleados basándose en esas ventas más altas. La partición por `employee_id` aquí rankea las ventas *dentro de cada empleado*, lo cual no es el rank global solicitado.
*   La complejidad de la CTE recursiva y los múltiples joins anidados la hacen muy difícil de depurar y entender. El enfoque de "sumar un marcador" para identificar grupos de rachas suele ser más estándar y a menudo más fácil de implementar con funciones de ventana.

### Ejercicio 4.2: Análisis Departamental del Rendimiento de Tareas

> **Problema:** Para cada departamento:
> 1.  Tareas totales mensuales por empleado por mes.
> 2.  Para cada total mensual del empleado, mostrar tareas del mes anterior y siguiente (por defecto 0).
> 3.  `mom_task_change_pct`.
> 4.  `feb_task_rank_in_dept`: `ROW_NUMBER` por empleado en departamento basado en tareas totales en Feb 2023 (más alto a más bajo). Solo para datos de Feb.
> 5.  Identifica empleados con tareas mensuales > 20% por encima del promedio de tareas de su departamento para ese mes. Muestra detalles.
> Ordena el punto 5 por departamento, empleado, mes.

*(El fragmento presenta varias CTEs y luego un `SELECT` para el punto 5. Parece que los puntos 1-4 se construyen en las CTEs y el `SELECT` final es para el punto 5, aunque el `JOIN` final del fragmento intenta unir `MonthlyPercentageChange` con `FebruaryRanking` lo cual podría no ser el informe final completo.)*

**Crítica y Estructura Conceptual del Fragmento de Ejercicio 4.2:**

1.  **`EmployeeMonthlyTasked` CTE:**
    *   Correcto: Agrupa tareas por empleado y mes.
    ```sql
    WITH EmployeeMonthlyTasked AS (
        SELECT
            employee_id,
            department, -- Necesario para particionar por departamento más tarde
            DATE_TRUNC('month', metric_date) AS task_month,
            SUM(tasks_completed) AS totalMonthlyTasks
        FROM analytical_cons_navigate_functions.employee_performance
        GROUP BY employee_id, department, DATE_TRUNC('month', metric_date)
    )
    ```

2.  **`SequentialTotalMonthlyTasks` CTE (Puntos 1, 2):**
    *   Correcto: Usa `LAG` y `LEAD` sobre `EmployeeMonthlyTasked` para obtener tareas del mes anterior/siguiente. `ranking` no es estrictamente necesario si se usa `LAG`/`LEAD` directamente.
    ```sql
    SequentialTotalMonthlyTasks AS (
        SELECT
            *,
            LAG(totalMonthlyTasks, 1, 0) OVER (PARTITION BY employee_id ORDER BY task_month) AS previous_monthly_tasks,
            LEAD(totalMonthlyTasks, 1, 0) OVER (PARTITION BY employee_id ORDER BY task_month) AS next_monthly_tasks
        FROM EmployeeMonthlyTasked
    )
    ```

3.  **`MonthlyPercentageChange` CTE (Punto 3):**
    *   Calcula `mom_task_change_pct`. El `LATERAL` aquí es una forma de hacerlo fila por fila; también se podría hacer directamente en `SequentialTotalMonthlyTasks`.
    *   Manejo de `previousmonthlytasks = 0`: `s2.totalMonthlyTasks::NUMERIC / NULLIF(s2.previousmonthlytasks, 0)` evitaría división por cero y daría `NULL`. El problema pide "100% si anterior fue 0 y actual > 0".
    ```sql
    MonthlyPercentageChange AS (
        SELECT
            *,
            CASE
                WHEN previous_monthly_tasks = 0 AND totalMonthlyTasks > 0 THEN 100.0 -- O un valor grande para indicar >100%
                WHEN previous_monthly_tasks = 0 AND totalMonthlyTasks = 0 THEN 0.0
                WHEN previous_monthly_tasks IS NULL THEN NULL -- Primer mes
                WHEN previous_monthly_tasks > 0 THEN ROUND(((totalMonthlyTasks::NUMERIC - previous_monthly_tasks) / previous_monthly_tasks) * 100.0, 2)
                ELSE NULL -- Caso donde previous_monthly_tasks es negativo o no manejado
            END AS mom_task_change_pct
        FROM SequentialTotalMonthlyTasks
    )
    ```

4.  **`FebruaryRanking` CTE (Punto 4):**
    *   Correcto: Calcula el rango para Febrero de 2023.
    ```sql
    FebruaryRanking AS (
        SELECT
            employee_id,
            department,
            ROW_NUMBER() OVER (PARTITION BY department ORDER BY SUM(tasks_completed) DESC) AS feb_task_rank_in_dept
        FROM analytical_cons_navigate_functions.employee_performance
        WHERE DATE_TRUNC('month', metric_date) = DATE '2023-02-01'
        GROUP BY employee_id, department -- Agrupar por empleado para sumar tareas de Febrero
    )
    ```

5.  **CTEs para el Punto 5 (`AvgDepartmentalTasks`, `EmployeeMonthlyPerformance`, `SuperMonths`):**
    *   **`AvgDepartmentalTasks`**: Calcula el promedio de tareas completadas (¿diarias, mensuales?) *por departamento*. Si es mensual, debe agrupar por mes también. El fragmento lo agrupa solo por departamento, lo que da un promedio general del departamento. El problema pide "promedio de tareas de su departamento para *ese mismo mes*".
        ```sql
        -- Promedio mensual de tareas por departamento
        DepartmentMonthlyAvgTasks AS (
            SELECT
                department,
                DATE_TRUNC('month', metric_date) AS task_month,
                AVG(tasks_completed) AS dept_avg_tasks_for_month -- Esto es promedio de registros diarios
                -- Si es promedio de TAREAS TOTALES MENSUALES POR EMPLEADO:
                -- AVG(totalMonthlyTasks) OVER (PARTITION BY department, task_month) desde EmployeeMonthlyTasked
            FROM analytical_cons_navigate_functions.employee_performance
            GROUP BY department, DATE_TRUNC('month', metric_date)
        )
        ```
    *   **`EmployeeMonthlyPerformance`**: El fragmento une rendimiento con `AvgDepartmentalTasks`. Debería unirse con `DepartmentMonthlyAvgTasks` (el promedio mensual correcto).
    *   **`SuperMonths`**: Identifica correctamente los meses donde el empleado supera el 20% del promedio departamental (para ese mes).

**Final `SELECT` del fragmento para el punto 5:**
```sql
-- SELECT para el Punto 5 (conceptual, basado en CTEs refinadas)
SELECT
    emt.department,
    emt.employee_id,
    e.employee_name, -- Necesita join a employees
    emt.task_month AS qualifying_month_year,
    emt.totalMonthlyTasks AS employee_total_tasks_monthly,
    dmat.dept_avg_tasks_for_month
FROM EmployeeMonthlyTasked emt
JOIN DepartmentMonthlyAvgTasks dmat
    ON emt.department = dmat.department AND emt.task_month = dmat.task_month
JOIN analytical_cons_navigate_functions.employees e ON emt.employee_id = e.employee_id -- Para obtener nombre
WHERE emt.totalMonthlyTasks > (dmat.dept_avg_tasks_for_month * 1.20)
ORDER BY emt.department, e.employee_name, emt.task_month;
```
El `SELECT` final del fragmento (`SELECT m.*, f.department, f.feb_task_rank_in_dept FROM MonthlyPercentageChange m JOIN FebruaryRanking f USING(employee_id);`) parece ser una consulta intermedia para combinar los resultados de los puntos 1-4, no específicamente la salida del punto 5. El último `SELECT` del fragmento sí aborda el punto 5.

Este tipo de problema requiere una cuidadosa construcción de CTEs paso a paso para asegurar que cada métrica se calcula correctamente antes de combinarla para el informe final.