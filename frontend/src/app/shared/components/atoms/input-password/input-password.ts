import { Component, Input, forwardRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ControlValueAccessor, NG_VALUE_ACCESSOR, ReactiveFormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';

@Component({
  selector: 'app-input-password',
  standalone: true,
  imports: [CommonModule, IconComponent, ReactiveFormsModule],
  template: `
    <div class="input-password">
      <input
        [type]="type"
        [placeholder]="placeholder"
        [value]="value"
        [disabled]="disabled"
        (input)="onInput($event)"
        (blur)="onTouched()"
        class="input-password__field"
        [class.input-password__field--error]="hasError"
      />
      <button
        type="button"
        class="input-password__toggle"
        (click)="toggleVisibility()"
        [disabled]="disabled"
      >
        <app-icon [name]="showPassword ? 'eye-off' : 'eye'" [size]="20"></app-icon>
      </button>
    </div>
  `,
  styles: [`
    @use 'variables' as *;
    @use 'mixins' as *;

    .input-password {
      position: relative;
      display: flex;
      align-items: center;

      &__field {
        width: 100%;
        padding: $spacing-md $spacing-3xl $spacing-md $spacing-md;
        border: 2px solid var(--border-color);
        border-radius: $radius-lg;
        font-size: $font-size-base;
        color: var(--text-primary);
        background: var(--surface-primary);
        @include transition(all);

        &:focus {
          outline: none;
          border-color: var(--primary-500);
        }

        &:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }

        &--error {
          border-color: var(--red-500);
        }
      }

      &__toggle {
        position: absolute;
        right: $spacing-md;
        background: none;
        border: none;
        cursor: pointer;
        color: var(--text-secondary);
        @include transition(color);

        &:hover:not(:disabled) {
          color: var(--primary-600);
        }

        &:disabled {
          cursor: not-allowed;
        }
      }
    }
  `],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => InputPasswordComponent),
      multi: true
    }
  ]
})
export class InputPasswordComponent implements ControlValueAccessor {
  @Input() placeholder = '';
  @Input() disabled = false;
  @Input() hasError = false;

  value = '';
  showPassword = false;
  
  onChange: any = () => {};
  onTouched: any = () => {};

  get type(): string {
    return this.showPassword ? 'text' : 'password';
  }

  toggleVisibility(): void {
    this.showPassword = !this.showPassword;
  }

  onInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.value = target.value;
    this.onChange(this.value);
  }

  writeValue(value: string): void {
    this.value = value || '';
  }

  registerOnChange(fn: any): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: any): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }
}
