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

  constructor(
    private router: Router
  ) {}

  ngAfterViewInit(): void {

    this.codigoInput
      .nativeElement
      .focus();
  }

  volverInicio(): void {

    this.router.navigate([
      '/home'
    ]);
  }
}