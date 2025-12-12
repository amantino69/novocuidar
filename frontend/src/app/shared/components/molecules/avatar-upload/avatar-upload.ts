import { Component, EventEmitter, Input, Output } from '@angular/core';
import { AvatarComponent } from '@app/shared/components/atoms/avatar/avatar';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { ImageCropperComponent, CropperResult } from '@app/shared/components/molecules/image-cropper/image-cropper';

@Component({
  selector: 'app-avatar-upload',
  imports: [AvatarComponent, IconComponent, ImageCropperComponent],
  templateUrl: './avatar-upload.html',
  styleUrl: './avatar-upload.scss'
})
export class AvatarUploadComponent {
  @Input() name: string = '';
  @Input() currentAvatar?: string;
  @Output() avatarChange = new EventEmitter<string>();

  showCropper = false;
  selectedImageUrl = '';

  onFileSelect(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];

    if (file) {
      // Validar tipo de arquivo
      if (!file.type.startsWith('image/')) {
        alert('Por favor, selecione uma imagem válida');
        return;
      }

      // Validar tamanho (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        alert('A imagem deve ter no máximo 5MB');
        return;
      }

      // Criar URL temporária para preview
      const reader = new FileReader();
      reader.onload = (e) => {
        this.selectedImageUrl = e.target?.result as string;
        this.showCropper = true;
      };
      reader.readAsDataURL(file);
    }

    // Limpar input para permitir selecionar o mesmo arquivo novamente
    input.value = '';
  }

  onCropComplete(result: CropperResult): void {
    this.avatarChange.emit(result.imageUrl);
    this.showCropper = false;
    this.selectedImageUrl = '';
  }

  onCropCancel(): void {
    this.showCropper = false;
    this.selectedImageUrl = '';
    
    // Revogar URL temporária se existir
    if (this.selectedImageUrl) {
      URL.revokeObjectURL(this.selectedImageUrl);
    }
  }

  triggerFileInput(): void {
    const input = document.getElementById('avatar-file-input') as HTMLInputElement;
    input?.click();
  }
}
