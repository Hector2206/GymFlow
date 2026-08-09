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

  async verificarConexion() {
    try {
      const health = await fetch(
        'https://projectgym-t958.onrender.com/health'
      );

      if (health.ok) {
        this.estadoBackend = '🟢 Conectado';
      } else {
        this.estadoBackend = '🔴 Error';
      }

      const ping = await fetch(
        'https://projectgym-t958.onrender.com/ping'
      );

      if (ping.ok) {
        this.estadoBaseDatos = '🟢 Conectada';
      } else {
        this.estadoBaseDatos = '🔴 Error';
      }

    } catch {
      this.estadoBackend = '🔴 Sin conexión';
      this.estadoBaseDatos = '🔴 Sin conexión';
    }
  }
}