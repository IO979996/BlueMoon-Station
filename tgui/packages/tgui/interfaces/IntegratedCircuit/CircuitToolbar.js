import { Box, Button, Icon, Stack } from '../../components';

/**
 * Верхняя панель: состояние платы, счётчики, масштаб, краткая легенда управления.
 */
export const CircuitToolbar = (props) => {
  const {
    circuitOn,
    componentCount,
    variableCount,
    zoomPercent,
    showVariableChip = true,
    /** IE assembly only: null = no cell, number = charge % */
    ieBatteryPercent,
    /** IE: "assembly" | "chip" — показать кнопку копирования JSON для принтера / одного чипа */
    ieCloneCopyMode,
    onIeCloneCopy,
  } = props;

  const powered = circuitOn !== false && circuitOn !== 0;

  return (
    <Box className="IntegratedCircuit__toolbar">
      <Stack align="center" wrap="wrap">
        <Stack.Item>
          <Box
            className={powered
              ? 'IntegratedCircuit__chip IntegratedCircuit__chip--on'
              : 'IntegratedCircuit__chip IntegratedCircuit__chip--off'}>
            <Icon name="power-off" style={{ 'margin-right': '0.35em' }} />
            {powered ? 'Плата вкл.' : 'Плата выкл.'}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box
            className="IntegratedCircuit__chip IntegratedCircuit__chip--muted"
            title={ieBatteryPercent !== undefined
              ? 'Считаются только микросхемы (чипы с интегрального принтера). Батарея — отдельно.'
              : undefined}>
            <Icon name="microchip" style={{ 'margin-right': '0.35em' }} />
            {ieBatteryPercent !== undefined ? 'Чипов (принтер)' : 'Компонентов'}
            : <b>{componentCount}</b>
          </Box>
        </Stack.Item>
        {ieBatteryPercent !== undefined && (
          <Stack.Item>
            <Box
              className="IntegratedCircuit__chip IntegratedCircuit__chip--muted"
              title="Элемент питания в отсеке батареи, не логический чип.">
              <Icon name="battery-half" style={{ 'margin-right': '0.35em' }} />
              Батарея:{' '}
              <b>{ieBatteryPercent === null ? 'нет' : `${ieBatteryPercent}%`}</b>
            </Box>
          </Stack.Item>
        )}
        {!!showVariableChip && (
          <Stack.Item>
            <Box className="IntegratedCircuit__chip IntegratedCircuit__chip--muted">
              <Icon name="database" style={{ 'margin-right': '0.35em' }} />
              Переменных: <b>{variableCount}</b>
            </Box>
          </Stack.Item>
        )}
        {(ieCloneCopyMode === 'assembly' || ieCloneCopyMode === 'chip') && !!onIeCloneCopy && (
          <Stack.Item>
            <Button
              color="transparent"
              icon="copy"
              compact
              tooltip={ieCloneCopyMode === 'assembly'
                ? 'Код сборки (JSON) для принтера — как ghost scan / анализатор'
                : 'JSON одного чипа (имя, входы) — открыть и скопировать из окна'}
              onClick={onIeCloneCopy}>
              {ieCloneCopyMode === 'assembly' ? 'Код сборки' : 'Код чипа'}
            </Button>
          </Stack.Item>
        )}
        <Stack.Item>
          <Box className="IntegratedCircuit__chip IntegratedCircuit__chip--muted">
            <Icon name="search-plus" style={{ 'margin-right': '0.35em' }} />
            Масштаб: <b>{zoomPercent}</b>%
          </Box>
        </Stack.Item>
        <Stack.Item grow className="IntegratedCircuit__legendWrap">
          <Box
            className="IntegratedCircuit__legend"
            title={
              'Поле: перетаскивание ЛКМ. '
              + 'Нода: перетаскивание за заголовок. '
              + 'Связь: ЛКМ от выхода (справа) ко входу (слева). '
              + 'Снять связь: ПКМ по порту. '
              + 'Несколько проводов на вход: кнопки ⇄ меняют порядок. '
              + 'Масштаб: кнопки +/− у полосы внизу.'
            }>
            <Icon
              name="mouse-pointer"
              style={{ 'margin-right': '0.35em', opacity: 0.75 }}
            />
            Поле · ЛКМ — сдвиг · +/− — зум · связь выход→вход · ПКМ — снять
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
