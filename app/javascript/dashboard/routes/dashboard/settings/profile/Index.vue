<template>
  <div class="columns profile--settings">
    <form @submit.prevent="updateUser('profile')">
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3">
          <h4 class="block-title">
            {{ $t('PROFILE_SETTINGS.FORM.PROFILE_SECTION.TITLE') }}
          </h4>
          <p>{{ $t('PROFILE_SETTINGS.FORM.PROFILE_SECTION.NOTE') }}</p>
        </div>
        <div class="columns small-9 medium-5">
          <woot-avatar-uploader
            :label="$t('PROFILE_SETTINGS.FORM.PROFILE_IMAGE.LABEL')"
            :src="avatarUrl"
            @change="handleImageUpload"
          />
          <div v-if="showDeleteButton" class="avatar-delete-btn">
            <woot-button
              type="button"
              color-scheme="alert"
              variant="hollow"
              size="small"
              @click="deleteAvatar"
            >
              {{ $t('PROFILE_SETTINGS.DELETE_AVATAR') }}
            </woot-button>
          </div>
          <label :class="{ error: $v.name.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model="name"
              type="text"
              :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
              @input="$v.name.$touch"
            />
            <span v-if="$v.name.$error" class="message">
              {{ $t('PROFILE_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <label :class="{ error: $v.displayName.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.LABEL') }}
            <input
              v-model="displayName"
              type="text"
              :placeholder="
                $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.PLACEHOLDER')
              "
              @input="$v.displayName.$touch"
            />
          </label>
          <label
            v-if="!globalConfig.disableUserProfileUpdate"
            :class="{ error: $v.email.$error }"
          >
            {{ $t('PROFILE_SETTINGS.FORM.EMAIL.LABEL') }}
            <input
              v-model.trim="email"
              type="email"
              :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
              @input="$v.email.$touch"
            />
            <span v-if="$v.email.$error" class="message">
              {{ $t('PROFILE_SETTINGS.FORM.EMAIL.ERROR') }}
            </span>
          </label>
          <woot-button type="submit" :is-loading="isProfileUpdating">
            {{ $t('PROFILE_SETTINGS.BTN_TEXT') }}
          </woot-button>
        </div>
      </div>
    </form>
    <message-signature />
    <div class="profile--settings--row row">
      <div class="columns small-3">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.TITLE') }}
        </h4>
        <p>
          {{ $t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.NOTE') }}
        </p>
      </div>
      <div class="columns small-9 medium-5 card-preview">
        <button
          v-for="keyOption in keyOptions"
          :key="keyOption.key"
          class="preview-button"
          @click="toggleEditorMessageKey(keyOption.key)"
        >
          <preview-card
            :heading="keyOption.heading"
            :content="keyOption.content"
            :src="keyOption.src"
            :active="isEditorHotKeyEnabled(uiSettings, keyOption.key)"
          />
        </button>
      </div>
    </div>
    <change-password v-if="!globalConfig.disableUserProfileUpdate" />
    <notification-settings />
  </div>
</template>

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import { clearCookiesOnLogout } from '../../../../store/utils/api';
import NotificationSettings from './NotificationSettings';
import alertMixin from 'shared/mixins/alertMixin';
import ChangePassword from './ChangePassword';
import MessageSignature from './MessageSignature';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import uiSettingsMixin, {
  isEditorHotKeyEnabled,
} from 'dashboard/mixins/uiSettings';
import MaskedText from 'dashboard/components/MaskedText.vue';
import PreviewCard from 'dashboard/components/ui/PreviewCard.vue';

export default {
  components: {
    NotificationSettings,
    ChangePassword,
    MessageSignature,
    PreviewCard,
    MaskedText,
  },
  mixins: [alertMixin, globalConfigMixin, uiSettingsMixin],
  data() {
    return {
      avatarFile: '',
      avatarUrl: '',
      name: '',
      displayName: '',
      email: '',
      isProfileUpdating: false,
      errorMessage: '',
      keyOptions: [
        {
          key: 'enter',
          src: '/assets/images/dashboard/editor/enter-editor.png',
          heading: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.HEADING'
          ),
          content: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.CONTENT'
          ),
        },
        {
          key: 'cmd_enter',
          src: '/assets/images/dashboard/editor/cmd-editor.png',
          heading: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.HEADING'
          ),
          content: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.CONTENT'
          ),
        },
      ],
    };
  },
  validations: {
    name: {
      required,
      minLength: minLength(1),
    },
    displayName: {},
    email: {
      required,
      email,
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserId: 'getCurrentUserID',
      globalConfig: 'globalConfig/get',
    }),
  },
  watch: {
    currentUserId(newCurrentUserId, prevCurrentUserId) {
      if (prevCurrentUserId !== newCurrentUserId) {
        this.initializeUser();
      }
    },
  },
  mounted() {
    if (this.currentUserId) {
      this.initializeUser();
    }
  },
  methods: {
    initializeUser() {
      this.name = this.currentUser.name;
      this.email = this.currentUser.email;
      this.avatarUrl = this.currentUser.avatar_url;
      this.displayName = this.currentUser.display_name;
    },
    isEditorHotKeyEnabled,
    async updateUser() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }

      this.isProfileUpdating = true;
      const hasEmailChanged = this.currentUser.email !== this.email;
      try {
        await this.$store.dispatch('updateProfile', {
          name: this.name,
          email: this.email,
          avatar: this.avatarFile,
          displayName: this.displayName,
        });
        this.isProfileUpdating = false;
        if (hasEmailChanged) {
          clearCookiesOnLogout();
          this.errorMessage = this.$t('PROFILE_SETTINGS.AFTER_EMAIL_CHANGED');
        }
        this.errorMessage = this.$t('PROFILE_SETTINGS.UPDATE_SUCCESS');
      } catch (error) {
        this.errorMessage = this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
        if (error?.response?.data?.error) {
          this.errorMessage = error.response.data.error;
        }
      } finally {
        this.isProfileUpdating = false;
        this.showAlert(this.errorMessage);
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    async deleteAvatar() {
      try {
        await this.$store.dispatch('deleteAvatar');
        this.avatarUrl = '';
        this.avatarFile = '';
        this.showAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_SUCCESS'));
      } catch (error) {
        this.showAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_FAILED'));
      }
    },
    showDeleteButton() {
      return this.avatarUrl && !this.avatarUrl.includes('www.gravatar.com');
    },
    toggleEditorMessageKey(key) {
      this.updateUISettings({ editor_message_key: key });
      this.showAlert(
        this.$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.UPDATE_SUCCESS')
      );
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables.scss';
@import '~dashboard/assets/scss/mixins.scss';

.profile--settings {
  overflow: auto;
  padding: 24px;
}

.profile--settings--row {
  @include border-normal-bottom;
  align-items: center;
  display: flex;
  padding: $space-normal;

  .small-3 {
    padding: $space-normal $space-medium $space-normal 0;
  }

  .small-9 {
    padding: $space-normal;
  }

  .card-preview {
    display: flex;
    flex-direction: row;

    .preview-button {
      cursor: pointer;
      margin-right: var(--space-normal);
    }
  }
}
</style>
