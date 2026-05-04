
CREATE DATABASE GestorFinanzas;
GO

USE GestorFinanzas;
GO

CREATE TABLE Usuarios (
    UsuarioID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Contraseña NVARCHAR(255) NOT NULL,
    Ocupacion NVARCHAR(100),
    SaldoInicial DECIMAL(18,2) NOT NULL DEFAULT 0,
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    FechaActualizacion DATETIME NOT NULL DEFAULT GETDATE(),
    Activo BIT NOT NULL DEFAULT 1
);

CREATE TABLE Categorias (
    CategoriaID INT PRIMARY KEY IDENTITY(1,1),
    UsuarioID INT NOT NULL,
    Nombre NVARCHAR(50) NOT NULL,
    Tipo NVARCHAR(20) NOT NULL CHECK (Tipo IN ('ingreso', 'gasto')), -- ingreso o gasto
    Color NVARCHAR(7), -- Color en hexadecimal (ej: #FF5733)
    Icono NVARCHAR(50), -- Nombre del icono
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID) ON DELETE CASCADE,
    CONSTRAINT UK_Categorias UNIQUE (UsuarioID, Nombre, Tipo)
);

CREATE TABLE Cuentas (
    CuentaID INT PRIMARY KEY IDENTITY(1,1),
    UsuarioID INT NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Tipo NVARCHAR(50) NOT NULL CHECK (Tipo IN ('efectivo', 'ahorros', 'corriente', 'tarjeta_credito', 'otra')),
    SaldoActual DECIMAL(18,2) NOT NULL DEFAULT 0,
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    FechaActualizacion DATETIME NOT NULL DEFAULT GETDATE(),
    Activa BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID) ON DELETE CASCADE
);

CREATE TABLE Transacciones (
    TransaccionID INT PRIMARY KEY IDENTITY(1,1),
    UsuarioID INT NOT NULL,
    CuentaID INT NOT NULL,
    CategoriaID INT,
    Descripcion NVARCHAR(255) NOT NULL,
    Monto DECIMAL(18,2) NOT NULL,
    Tipo NVARCHAR(20) NOT NULL CHECK (Tipo IN ('ingreso', 'gasto')),
    Fecha DATE NOT NULL,
    FechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    Nota NVARCHAR(500),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID) ON DELETE CASCADE,
    FOREIGN KEY (CuentaID) REFERENCES Cuentas(CuentaID),
    FOREIGN KEY (CategoriaID) REFERENCES Categorias(CategoriaID)
);

CREATE TABLE Presupuestos (
    PresupuestoID INT PRIMARY KEY IDENTITY(1,1),
    UsuarioID INT NOT NULL,
    CategoriaID INT NOT NULL,
    MontoLimite DECIMAL(18,2) NOT NULL,
    Mes INT NOT NULL CHECK (Mes BETWEEN 1 AND 12),
    Año INT NOT NULL,
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    Activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID) ON DELETE CASCADE,
    FOREIGN KEY (CategoriaID) REFERENCES Categorias(CategoriaID) ON DELETE CASCADE,
    CONSTRAINT UK_Presupuestos UNIQUE (UsuarioID, CategoriaID, Mes, Año)
);

CREATE INDEX IX_Categorias_UsuarioID ON Categorias(UsuarioID);
CREATE INDEX IX_Cuentas_UsuarioID ON Cuentas(UsuarioID);
CREATE INDEX IX_Transacciones_UsuarioID ON Transacciones(UsuarioID);
CREATE INDEX IX_Transacciones_CuentaID ON Transacciones(CuentaID);
CREATE INDEX IX_Transacciones_Fecha ON Transacciones(Fecha);
CREATE INDEX IX_Transacciones_Tipo ON Transacciones(Tipo);
CREATE INDEX IX_Presupuestos_UsuarioID ON Presupuestos(UsuarioID);
CREATE VIEW vw_SaldoPorCuenta AS
SELECT 
    c.CuentaID,
    c.UsuarioID,
    c.Nombre AS NombreCuenta,
    c.Tipo AS TipoCuenta,
    c.SaldoActual,
    COUNT(t.TransaccionID) AS TotalTransacciones,
    SUM(CASE WHEN t.Tipo = 'ingreso' THEN t.Monto ELSE 0 END) AS TotalIngresos,
    SUM(CASE WHEN t.Tipo = 'gasto' THEN t.Monto ELSE 0 END) AS TotalGastos
FROM Cuentas c
LEFT JOIN Transacciones t ON c.CuentaID = t.CuentaID
GROUP BY c.CuentaID, c.UsuarioID, c.Nombre, c.Tipo, c.SaldoActual;

CREATE VIEW vw_GastoMensualPorCategoria AS
SELECT 
    u.UsuarioID,
    u.Nombre AS NombreUsuario,
    MONTH(t.Fecha) AS Mes,
    YEAR(t.Fecha) AS Año,
    c.Nombre AS NombreCategoria,
    SUM(CASE WHEN t.Tipo = 'gasto' THEN t.Monto ELSE 0 END) AS TotalGastos,
    SUM(CASE WHEN t.Tipo = 'ingreso' THEN t.Monto ELSE 0 END) AS TotalIngresos
FROM Transacciones t
JOIN Usuarios u ON t.UsuarioID = u.UsuarioID
LEFT JOIN Categorias c ON t.CategoriaID = c.CategoriaID
GROUP BY u.UsuarioID, u.Nombre, MONTH(t.Fecha), YEAR(t.Fecha), c.Nombre;

CREATE VIEW vw_MonitoreoPrespuestos AS
SELECT 
    p.PresupuestoID,
    p.UsuarioID,
    c.Nombre AS NombreCategoria,
    p.MontoLimite,
    p.Mes,
    p.Año,
    COALESCE(SUM(t.Monto), 0) AS GastoActual,
    CASE 
        WHEN COALESCE(SUM(t.Monto), 0) > p.MontoLimite THEN 'Excedido'
        WHEN COALESCE(SUM(t.Monto), 0) > (p.MontoLimite * 0.8) THEN 'En Alerta'
        ELSE 'Normal'
    END AS Estado
FROM Presupuestos p
JOIN Categorias c ON p.CategoriaID = c.CategoriaID
LEFT JOIN Transacciones t ON t.CategoriaID = p.CategoriaID 
    AND t.UsuarioID = p.UsuarioID
    AND MONTH(t.Fecha) = p.Mes
    AND YEAR(t.Fecha) = p.Año
    AND t.Tipo = 'gasto'
GROUP BY p.PresupuestoID, p.UsuarioID, c.Nombre, p.MontoLimite, p.Mes, p.Año;
CREATE PROCEDURE sp_RegistrarTransaccion
    @UsuarioID INT,
    @CuentaID INT,
    @CategoriaID INT = NULL,
    @Descripcion NVARCHAR(255),
    @Monto DECIMAL(18,2),
    @Tipo NVARCHAR(20),
    @Fecha DATE = NULL,
    @Nota NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE UsuarioID = @UsuarioID AND Activo = 1)
        BEGIN
            THROW 50001, 'Usuario no encontrado o inactivo', 1;
        END;
        IF NOT EXISTS (SELECT 1 FROM Cuentas WHERE CuentaID = @CuentaID AND UsuarioID = @UsuarioID)
        BEGIN
            THROW 50002, 'Cuenta no encontrada', 1;
        END;
        IF @Tipo = 'gasto'
        BEGIN
            DECLARE @SaldoActual DECIMAL(18,2);
            SELECT @SaldoActual = SaldoActual FROM Cuentas WHERE CuentaID = @CuentaID;
            
            IF @SaldoActual < @Monto
            BEGIN
                THROW 50003, 'Saldo insuficiente', 1;
            END;
        END;

        IF @Fecha IS NULL
            SET @Fecha = CAST(GETDATE() AS DATE);
        
        INSERT INTO Transacciones (UsuarioID, CuentaID, CategoriaID, Descripcion, Monto, Tipo, Fecha, Nota)
        VALUES (@UsuarioID, @CuentaID, @CategoriaID, @Descripcion, @Monto, @Tipo, @Fecha, @Nota);
        IF @Tipo = 'ingreso'
            UPDATE Cuentas SET SaldoActual = SaldoActual + @Monto, FechaActualizacion = GETDATE() WHERE CuentaID = @CuentaID;
        ELSE
            UPDATE Cuentas SET SaldoActual = SaldoActual - @Monto, FechaActualizacion = GETDATE() WHERE CuentaID = @CuentaID;
        
        COMMIT TRANSACTION;
        SELECT 'Transacción registrada exitosamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE PROCEDURE sp_ObtenerResumenMensual
    @UsuarioID INT,
    @Mes INT,
    @Año INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.Nombre AS NombreUsuario,
        @Mes AS Mes,
        @Año AS Año,
        COALESCE(SUM(CASE WHEN t.Tipo = 'ingreso' THEN t.Monto ELSE 0 END), 0) AS TotalIngresos,
        COALESCE(SUM(CASE WHEN t.Tipo = 'gasto' THEN t.Monto ELSE 0 END), 0) AS TotalGastos,
        COALESCE(SUM(CASE WHEN t.Tipo = 'ingreso' THEN t.Monto ELSE 0 END), 0) - 
        COALESCE(SUM(CASE WHEN t.Tipo = 'gasto' THEN t.Monto ELSE 0 END), 0) AS Diferencia
    FROM Usuarios u
    LEFT JOIN Transacciones t ON u.UsuarioID = t.UsuarioID
        AND MONTH(t.Fecha) = @Mes
        AND YEAR(t.Fecha) = @Año
    WHERE u.UsuarioID = @UsuarioID
    GROUP BY u.Nombre;
END;
GO
CREATE PROCEDURE sp_ObtenerTransaccionesPorFecha
    @UsuarioID INT,
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.TransaccionID,
        t.Descripcion,
        t.Monto,
        t.Tipo,
        t.Fecha,
        c.Nombre AS NombreCuenta,
        cat.Nombre AS NombreCategoria
    FROM Transacciones t
    JOIN Cuentas c ON t.CuentaID = c.CuentaID
    LEFT JOIN Categorias cat ON t.CategoriaID = cat.CategoriaID
    WHERE t.UsuarioID = @UsuarioID
        AND t.Fecha >= @FechaInicio
        AND t.Fecha <= @FechaFin
    ORDER BY t.Fecha DESC;
END;
GO
 --usuario de prueba /NO BORRAR
INSERT INTO Usuarios (Nombre, Email, Contraseña, Ocupacion, SaldoInicial)
VALUES ('Juan Pérez', 'juan@example.com', 'hashed_password_123', 'Ingeniero', 5000.00);

INSERT INTO Usuarios (Nombre, Email, Contraseña, Ocupacion, SaldoInicial)
VALUES ('María García', 'maria@example.com', 'hashed_password_456', 'Médico', 8000.00);

INSERT INTO Categorias (UsuarioID, Nombre, Tipo, Color, Icono)
VALUES 
(1, 'Salario', 'ingreso', '#2ECC71', 'money'),
(1, 'Freelance', 'ingreso', '#27AE60', 'briefcase'),
(1, 'Alimentación', 'gasto', '#E74C3C', 'shopping-cart'),
(1, 'Transporte', 'gasto', '#3498DB', 'car'),
(1, 'Entretenimiento', 'gasto', '#F39C12', 'smile'),
(1, 'Servicios', 'gasto', '#9B59B6', 'home'),
(2, 'Salario', 'ingreso', '#2ECC71', 'money'),
(2, 'Alimentación', 'gasto', '#E74C3C', 'shopping-cart'),
(2, 'Medicinas', 'gasto', '#E67E22', 'pills');

INSERT INTO Cuentas (UsuarioID, Nombre, Tipo, SaldoActual)
VALUES 
(1, 'Efectivo', 'efectivo', 1000.00),
(1, 'Cuenta Ahorros Banco X', 'ahorros', 3500.00),
(1, 'Tarjeta Crédito', 'tarjeta_credito', 500.00),
(2, 'Efectivo', 'efectivo', 2000.00),
(2, 'Cuenta Corriente', 'corriente', 5000.00);

INSERT INTO Transacciones (UsuarioID, CuentaID, CategoriaID, Descripcion, Monto, Tipo, Fecha, Nota)
VALUES 
(1, 1, 1, 'Salario mensual', 3000.00, 'ingreso', '2026-04-01', 'Pago por mes de abril'),
(1, 1, 3, 'Compra en supermercado', 150.00, 'gasto', '2026-04-05', 'Alimentos para la semana'),
(1, 2, 4, 'Gasolina', 80.00, 'gasto', '2026-04-08', 'Llenar tanque'),
(1, 1, 5, 'Cine', 30.00, 'gasto', '2026-04-10', 'Entrada película'),
(1, 1, 2, 'Proyecto freelance', 500.00, 'ingreso', '2026-04-15', 'Pago cliente'),
(2, 4, 7, 'Salario', 5000.00, 'ingreso', '2026-04-01', 'Salario mes de abril'),
(2, 4, 8, 'Supermercado', 200.00, 'gasto', '2026-04-05', 'Compras diarias'),
(2, 5, 9, 'Medicinas farmacia', 120.00, 'gasto', '2026-04-12', 'Prescripción médica');

INSERT INTO Presupuestos (UsuarioID, CategoriaID, MontoLimite, Mes, Año, Activo)
VALUES 
(1, 3, 500.00, 4, 2026, 1),  -- Presupuesto de 500 para Alimentación en abril
(1, 4, 300.00, 4, 2026, 1),  -- Presupuesto de 300 para Transporte en abril
(1, 5, 200.00, 4, 2026, 1),  -- Presupuesto de 200 para Entretenimiento en abril
(2, 8, 400.00, 4, 2026, 1),  -- Presupuesto de 400 para Alimentación en abril
(2, 9, 300.00, 4, 2026, 1);  -- Presupuesto de 300 para Medicinas en abril

SELECT 'Base de datos creada exitosamente' AS Mensaje;
SELECT COUNT(*) AS TotalUsuarios FROM Usuarios;
SELECT COUNT(*) AS TotalCategorias FROM Categorias;
SELECT COUNT(*) AS TotalCuentas FROM Cuentas;
SELECT COUNT(*) AS TotalTransacciones FROM Transacciones;
SELECT COUNT(*) AS TotalPresupuestos FROM Presupuestos;
