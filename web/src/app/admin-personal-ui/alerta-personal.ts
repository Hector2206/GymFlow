
import {
  Component,
  Input,
  OnChanges,
  SimpleChanges
} from '@angular/core';

@Component({
  selector: 'app-alerta-personal',
  standalone: true,

  template: `
    @if (visible && (error || exito)) {

      <div class="alerta-capa">

        <section
          class="alerta-tarjeta"
          [class.alerta-error]="!!error"
          [attr.role]="error ? 'alert' : 'status'"
          [attr.aria-live]="error ? 'assertive' : 'polite'"
          aria-atomic="true"
        >

          <div class="alerta-icono">
            {{ error ? '!' : '✓' }}
          </div>

          <div class="alerta-contenido">

            <strong>
              {{
                error
                  ? 'Atención'
                  : tituloExito
              }}
            </strong>

            <p>
              {{ error || exito }}
            </p>

          </div>

          <button
            type="button"
            class="alerta-cerrar"
            (click)="cerrar()"
            aria-label="Cerrar aviso"
            title="Cerrar aviso"
          >
            ×
          </button>

        </section>

      </div>

    }
  `,

  styles: [`

    :host {
      display: block;
    }

    .alerta-capa {
      position: fixed;
      top: calc(16px + env(safe-area-inset-top, 0px));
      left: 0;
      right: 0;

      z-index: 3000;

      display: flex;
      justify-content: center;

      padding: 0 16px;
      pointer-events: none;
    }

    .alerta-tarjeta {
      box-sizing: border-box;

      width: 100%;
      max-width: 540px;
      max-height: calc(100dvh - 40px);

      display: flex;
      align-items: flex-start;
      gap: 14px;

      padding: 20px;

      border: 1px solid #d8bf86;
      border-radius: 16px;

      background: #fffaf0;

      box-shadow:
        0 12px 40px rgba(65, 48, 20, 0.18);

      color: #493617;

      pointer-events: auto;
      overflow-y: auto;

      animation: aparecerAlerta 0.25s ease;
    }

    .alerta-icono {
      width: 36px;
      height: 36px;
      flex-shrink: 0;

      display: flex;
      align-items: center;
      justify-content: center;

      border-radius: 50%;

      background: #e7d5a9;
      color: #7c5915;

      font-size: 23px;
      font-weight: 800;
    }

    .alerta-contenido {
      min-width: 0;
      flex: 1;
    }

    .alerta-contenido strong {
      display: block;

      margin-bottom: 6px;

      font-size: 16px;
      font-weight: 700;
    }

    .alerta-contenido p {
      margin: 0;

      font-size: 13px;
      line-height: 1.6;

      overflow-wrap: anywhere;
    }

    .alerta-error {
      border-color: #e8b6b1;
      background: #fff2f0;
      color: #8f3034;
    }

    .alerta-error .alerta-icono {
      background: #f5d7d4;
      color: #a52f35;
    }

    .alerta-cerrar {
      border: none;
      background: transparent;

      color: inherit;
      font-size: 24px;
      line-height: 1;

      cursor: pointer;
      opacity: 0.7;

      padding: 2px 5px;
    }

    .alerta-cerrar:hover {
      opacity: 1;
    }

    .alerta-cerrar:focus-visible {
      outline: 2px solid currentColor;
      outline-offset: 3px;
      border-radius: 5px;
    }

    @keyframes aparecerAlerta {

      from {
        opacity: 0;
        transform: translateY(-14px);
      }

      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    @media (prefers-reduced-motion: reduce) {
      .alerta-tarjeta {
        animation: none;
      }
    }

    @media (max-width: 600px) {

      .alerta-capa {
        padding: 0 12px;
      }

      .alerta-tarjeta {
        padding: 15px;
        gap: 10px;
      }

      .alerta-contenido strong {
        font-size: 14px;
      }

      .alerta-contenido p {
        font-size: 12px;
      }

    }

  `]
})
export class AlertaPersonal implements OnChanges {

  @Input() error = '';
  @Input() exito = '';
  @Input() tituloExito = 'Operación realizada';

  visible = true;

  ngOnChanges(changes: SimpleChanges): void {

    if (
      (changes['error'] || changes['exito']) &&
      (this.error || this.exito)
    ) {
      this.visible = true;
    }

  }

  cerrar(): void {
    this.visible = false;
  }

}
