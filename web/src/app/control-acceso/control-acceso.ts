import {
  AfterViewInit,
  Component,
  ElementRef,
  ViewChild
} from '@angular/core';

import { Router } from '@angular/router';

@Component({
  selector: 'app-control-acceso',
  standalone: true,
  imports: [],
  templateUrl: './control-acceso.html',
  styleUrl: './control-acceso.css'
})
export class ControlAcceso implements AfterViewInit {

  @ViewChild('codigoInput')
  codigoInput!: ElementRef<HTMLInputElement>;

  codigoAcceso = '';

  constructor(
    private router: Router
  ) {}

  ngAfterViewInit(): void {

    this.codigoInput
      .nativeElement
      .focus();
  }

  capturarCodigo(
    event: Event
  ): void {

    const input =
      event.target as HTMLInputElement;

    this.codigoAcceso =
      input.value;
  }

  detectarEnter(): void {

    console.log(
      'Enter detectado. Código:',
      this.codigoAcceso
    );
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}