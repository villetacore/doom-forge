import {
  DndContext,
  closestCenter,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  arrayMove,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { Icon } from "../../components/Icon";
import { GROUP_LABELS, type LoadEntry } from "../../lib/types";
import { useT } from "../../i18n";

export default function LoadOrderEditor({
  entries,
  onChange,
}: {
  entries: LoadEntry[];
  onChange: (next: LoadEntry[]) => void;
}) {
  const t = useT();
  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 4 } }));

  function onDragEnd(e: DragEndEvent) {
    const { active, over } = e;
    if (!over || active.id === over.id) return;
    const from = entries.findIndex((x) => x.path === active.id);
    const to = entries.findIndex((x) => x.path === over.id);
    if (from < 0 || to < 0) return;
    onChange(arrayMove(entries, from, to));
  }

  if (entries.length === 0) {
    return <p className="empty">{t("build.loadOrderEmpty")}</p>;
  }

  return (
    <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={onDragEnd}>
      <SortableContext items={entries.map((e) => e.path)} strategy={verticalListSortingStrategy}>
        <ol className="load-order">
          {entries.map((entry, idx) => (
            <Row
              key={entry.path}
              entry={entry}
              index={idx}
              onToggle={() =>
                onChange(entries.map((x) => (x.path === entry.path ? { ...x, enabled: !x.enabled } : x)))
              }
              onRemove={() => onChange(entries.filter((x) => x.path !== entry.path))}
            />
          ))}
        </ol>
      </SortableContext>
    </DndContext>
  );
}

function Row({
  entry,
  index,
  onToggle,
  onRemove,
}: {
  entry: LoadEntry;
  index: number;
  onToggle: () => void;
  onRemove: () => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: entry.path,
  });
  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };
  return (
    <li ref={setNodeRef} style={style} className={"lo-row" + (entry.enabled ? "" : " disabled")}>
      <span className="drag" {...attributes} {...listeners}>
        <Icon name="sort" size={15} />
      </span>
      <span className="lo-index">{index + 1}</span>
      <input type="checkbox" style={{ width: "auto" }} checked={entry.enabled} onChange={onToggle} />
      <span className="lo-name" title={entry.path}>{entry.name}</span>
      <span className={`badge g-${entry.group}`}>{GROUP_LABELS[entry.group]}</span>
      <button className="icon-btn" onClick={onRemove}><Icon name="trash" size={14} /></button>
    </li>
  );
}
