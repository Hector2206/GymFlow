import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  estadoBackend = '⚪ Sin verificar';
  estadoBaseDatos = '⚪ Sin verificar';
  versionSistema = '⚪ Sin verificar';

  async verificarConexion() {
    try {
      // Verificar Backend
      const health = await fetch(
        'https://projectgym-t958.onrender.com/health'
      );

      if (health.ok) {
        this.estadoBackend = '🟢 Conectado';
      } else {
        this.estadoBackend = '🔴 Error';
      }

      // Verificar Base de Datos
      const ping = await fetch(
        'https://projectgym-t958.onrender.com/ping'
      );

      if (ping.ok) {
        this.estadoBaseDatos = '🟢 Conectada';
      } else {
        this.estadoBaseDatos = '🔴 Error';
      }

      // Obtener versión desde PostgreSQL
      const versionResponse = await fetch(
        'https://projectgym-t958.onrender.com/version'
      );

      if (versionResponse.ok) {
        const data = await versionResponse.json();
        this.versionSistema = data.version;
      } else {
        this.versionSistema = '🔴 Error';
      }

    } catch {
      this.estadoBackend = '🔴 Sin conexión';
      this.estadoBaseDatos = '🔴 Sin conexión';
      this.versionSistema = '🔴 Sin conexión';
    }
  }
}